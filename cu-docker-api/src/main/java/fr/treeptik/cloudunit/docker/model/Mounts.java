package fr.treeptik.cloudunit.docker.model;

import com.fasterxml.jackson.annotation.JsonProperty;

/**
 * Created by nicolas on 06/01/2016.
 */
public class Mounts {

    @JsonProperty("Source")
    private String source;

    @JsonProperty("Destination")
    private String destination;

    @JsonProperty("Mode")
    private String mode;

    @JsonProperty("RW")
    private Boolean readWrite;

    @Override
    public String toString() {
        return "Mounts{" +
                "source='" + source + '\'' +
                ", destination='" + destination + '\'' +
                ", mode='" + mode + '\'' +
                ", readWrite=" + readWrite +
                '}';
    }

    public String getSource() {
        return source;
    }

    public void setSource(String source) {
        this.source = source;
    }

    public String getDestination() {
        return destination;
    }

    public void setDestination(String destination) {
        this.destination = destination;
    }

    public String getMode() {
        return mode;
    }

    public void setMode(String mode) {
        this.mode = mode;
    }

    public Boolean getReadWrite() {
        return readWrite;
    }

    public void setReadWrite(Boolean readWrite) {
        this.readWrite = readWrite;
    }
}
