package com.spark.user.common.error;

import com.fasterxml.jackson.annotation.JsonFormat;
import lombok.Getter;

import java.time.LocalDateTime;

@Getter
public class ErrorResponseDto {

    @JsonFormat(pattern = "yyyy-MM-dd HH:mm:ss.SSS")
    private final LocalDateTime timestamp;

    private final int status;
    private final int code;
    private final String message;

    public ErrorResponseDto(ErrorCode errorCode) {
        this.timestamp = LocalDateTime.now();
        this.status = errorCode.getHttpStatus();
        this.code = errorCode.getCode();
        this.message = errorCode.getMessage();
    }
}
