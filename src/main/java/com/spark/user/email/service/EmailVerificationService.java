package com.spark.user.email.service;

import com.spark.user.email.dto.request.EmailVerificationRequestDto;
import com.spark.user.email.dto.response.EmailVerificationResponseDto;
import org.springframework.stereotype.Service;

@Service
public class EmailVerificationService {

    // TODO: 인증번호 발송 구현
    public EmailVerificationResponseDto createEmailVerification(EmailVerificationRequestDto request) {
        return EmailVerificationResponseDto.builder()
                .email(request.getEmail())
                .purpose(request.getPurpose())
                .build();
    }
}
