package com.spark.user.common.exception;

import lombok.extern.slf4j.Slf4j;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.ExceptionHandler;
import org.springframework.web.bind.annotation.RestControllerAdvice;

@Slf4j
@RestControllerAdvice
public class GlobalExceptionHandler {

    @ExceptionHandler(BusinessException.class)
    public ResponseEntity<ErrorResponseDto> handleBusinessException(BusinessException exception) {
        ErrorCode errorCode = exception.getErrorCode();
        if (errorCode.getHttpStatus() >= 500) {
            log.error("요청 처리 실패. code={}", errorCode.getCode(), exception);
        }
        ErrorResponseDto body = new ErrorResponseDto(errorCode);
        return ResponseEntity.status(errorCode.getHttpStatus()).body(body);
    }
}
