package com.spark.user.email.controller;

import com.spark.user.email.dto.request.EmailVerificationRequestDto;
import com.spark.user.email.dto.response.EmailVerificationResponseDto;
import com.spark.user.email.service.EmailVerificationService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.responses.ApiResponse;
import io.swagger.v3.oas.annotations.responses.ApiResponses;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/v1/email")
@RequiredArgsConstructor
@Tag(name = "이메일 인증", description = "인증번호 발송과 확인")
public class EmailVerificationController {

    private final EmailVerificationService emailVerificationService;

    @PostMapping("/verifications")
    @Operation(
            summary = "이메일 인증 발송/확인",
            description = "verificationCode가 없으면 발송(201), 있으면 확인(200)이다. 인증번호와 해시는 응답에 포함하지 않는다.")
    @ApiResponses({
            @ApiResponse(responseCode = "201", description = "인증번호 발송"),
            @ApiResponse(responseCode = "200", description = "인증번호 확인")
    })
    public ResponseEntity<EmailVerificationResponseDto> createEmailVerification(
            @Valid @RequestBody EmailVerificationRequestDto request) {
        EmailVerificationResponseDto body = emailVerificationService.createEmailVerification(request);
        boolean confirm = request.getVerificationCode() != null && !request.getVerificationCode().isBlank();
        HttpStatus status = confirm ? HttpStatus.OK : HttpStatus.CREATED;
        return ResponseEntity.status(status).body(body);
    }
}
