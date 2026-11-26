package com.spark.user.email.controller;

import com.spark.user.email.dto.request.EmailVerificationRequestDto;
import com.spark.user.email.dto.response.EmailVerificationResponseDto;
import com.spark.user.email.service.EmailVerificationService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.ResponseStatus;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/v1/email")
@RequiredArgsConstructor
@Tag(name = "이메일 인증", description = "인증번호 발송")
public class EmailVerificationController {

    private final EmailVerificationService emailVerificationService;

    @PostMapping("/verifications")
    @ResponseStatus(HttpStatus.CREATED)
    @Operation(summary = "이메일 인증 요청", description = "인증번호는 저장하거나 응답에 포함하지 않는다.")
    public EmailVerificationResponseDto createEmailVerification(
            @Valid @RequestBody EmailVerificationRequestDto request) {
        return emailVerificationService.createEmailVerification(request);
    }
}
