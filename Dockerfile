FROM busybox:1-ubuntu
VOLUME /data
ADD data /data
CMD ["true"]
