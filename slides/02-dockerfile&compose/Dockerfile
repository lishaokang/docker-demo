FROM registry.docimaxvip.com/base/java11:latest as java
COPY ./services /opt/docimax/yuntu-ofs
COPY ./entrypoint.sh /tmp/
EXPOSE 18082
CMD ["/opt/docimax/yuntu-ofs/bin/yuntu-ofs-service"]
ENTRYPOINT ["sh", "/tmp/entrypoint.sh"]