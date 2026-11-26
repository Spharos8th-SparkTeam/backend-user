package com.spark.user.email.dto.response;

import lombok.Builder;
import lombok.Getter;

import java.time.LocalDateTime;

@Getter
@Builder
public class EmailVerificationResponseDto {

    private final String email;
    private final String purpose;
    private final LocalDateTime expiresAt;
}
