package com.spark.user.email.dto.response;

import lombok.Builder;
import lombok.Getter;

@Getter
@Builder
public class EmailVerificationResponseDto {

    private final String email;
    private final String purpose;
}
