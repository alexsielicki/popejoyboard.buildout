# This is a basic VCL configuration file for varnish.  See the vcl(7)
# man page for details on VCL syntax and semantics.

backend schooltime_0 {
.host = "127.0.0.1";
.port = "7080";
.connect_timeout = 0.4s;
.first_byte_timeout = 300s;
.between_bytes_timeout = 60s;
}
backend board_0 {
.host = "127.0.0.1";
.port = "9090";
.connect_timeout = 0.4s;
.first_byte_timeout = 300s;
.between_bytes_timeout = 60s;
}

backend popejoypresents_0 {
.host = "127.0.0.1";
.port = "8080";
.connect_timeout = 0.4s;
.first_byte_timeout = 300s;
.between_bytes_timeout = 60s;
}
backend popejoypresents_1 {
.host = "127.0.0.1";
.port = "8081";
.connect_timeout = 0.4s;
.first_byte_timeout = 300s;
.between_bytes_timeout = 60s;
}
backend popejoypresents_2 {
.host = "127.0.0.1";
.port = "8082";
.connect_timeout = 0.4s;
.first_byte_timeout = 300s;
.between_bytes_timeout = 60s;
}
backend popejoypresents_3 {
.host = "127.0.0.1";
.port = "8083";
.connect_timeout = 0.4s;
.first_byte_timeout = 300s;
.between_bytes_timeout = 60s;
}
director popejoypresents random {
        {
                .backend = popejoypresents_0;
                .weight = 1;
        }
        {
                .backend = popejoypresents_1;
                .weight = 1;
        }
        {
                .backend = popejoypresents_2;
                .weight = 1;
        }
        {
                .backend = popejoypresents_3;
                .weight = 1;
        }
}


acl purge {
    "localhost";
    "127.0.0.1";
    "popejoypresents.com";
    "www.popejoypresents.com";
    "schooltimeseries.com";
    "www.schooltimeseries.com";
    "board.popejoypresents.com";
}

sub vcl_recv {
    set req.grace = 120s;
    if (req.http.host ~ "(?i)^(www.)?popejoypresents.com(:[0-9]+)?$") {
		set req.url = "/VirtualHostBase/http/popejoypresents.com:80/Plone/VirtualHostRoot" req.url;
		set req.backend = popejoypresents;
	}
	elsif (req.http.host ~ "(?i)^(www.)?schooltimeseries.com(:[0-9]+)?$") {
		set req.url = "/VirtualHostBase/http/schooltimeseries.com:80/Schooltime/VirtualHostRoot" req.url;
		set req.backend = schooltime_0;
	}
	elsif (req.http.host ~ "^board.popejoypresents.com(:[0-9]+)?$") {
		set req.url = "/VirtualHostBase/http/board.popejoypresents.com:80/Plone/VirtualHostRoot" req.url;
		set req.backend = board_0;
	}
    elsif (req.http.host ~ "^new.popejoypresents.com(:[0-9]+)?$") {
        set req.url = "/VirtualHostBase/http/new.popejoypresents.com:80/Plone/VirtualHostRoot" req.url;
        set req.backend = popejoypresents;
    }
	else {
		error 404 "Unknown virtual host";
	}



    if (req.request == "PURGE") {
        if (!client.ip ~ purge) {
            error 405 "Not allowed.";
        }
        return(lookup);
    }

    if (req.request != "GET" &&
        req.request != "HEAD" &&
        req.request != "PUT" &&
        req.request != "POST" &&
        req.request != "TRACE" &&
        req.request != "OPTIONS" &&
        req.request != "DELETE") {
        /* Non-RFC2616 or CONNECT which is weird. */
        return(pipe);
    }

    if (req.request != "GET" && req.request != "HEAD") {
        /* We only deal with GET and HEAD by default */
        return(pass);
    }

    if (req.http.If-None-Match) {
        return(pass);
    }

    if (req.url ~ "createObject") {
        return(pass);
    }

    remove req.http.Accept-Encoding;

    return(lookup);
}

sub vcl_pipe {
    # This is not necessary if you do not do any request rewriting.
    set req.http.connection = "close";

}

sub vcl_hit {

    if (req.request == "PURGE") {
        purge_url(req.url);
        error 200 "Purged";
    }

    if (!obj.cacheable) {
        return(pass);
    }
}

sub vcl_miss {

    if (req.request == "PURGE") {
        error 404 "Not in cache";
    }

}

sub vcl_fetch {
    set beresp.grace = 120s;

    if (!beresp.cacheable) {
        return(pass);
    }
    if (beresp.http.Set-Cookie) {
        return(pass);
    }
    if (beresp.http.Cache-Control ~ "(private|no-cache|no-store)") {
        return(pass);
    }
    if (beresp.http.Authorization && !beresp.http.Cache-Control ~ "public") {
        return(pass);
    }
    
}

sub vcl_deliver {

}
