FROM busybox
LABEL maintainer="Shaokang Li <lisk@docimax.com.cn>"

ENV WEB_DOC_ROOT="/data/web/html/"

RUN mkdir -p $WEB_DOC_ROOT && \
    echo "<h1>Busybox http server.</h1>" > ${WEB_DOC_ROOT}/index.html
#CMD /bin/httpd -f -h ${WEB_DOC_ROOT}
CMD ["/bin/httpd", "-f", "-h ${WEB_DOC_ROOT}"]