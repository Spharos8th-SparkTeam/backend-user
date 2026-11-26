package com.spark.user.auth.controller;

import com.spark.user.auth.dto.request.AuthLoginRequestDto;
import com.spark.user.auth.dto.request.AuthPasswordResetRequestDto;
import com.spark.user.auth.dto.request.AuthPasswordUpdateRequestDto;
import com.spark.user.auth.dto.request.AuthSignupRequestDto;
import com.spark.user.auth.dto.request.AuthSocialLoginRequestDto;
import com.spark.user.auth.dto.request.AuthSocialSignupRequestDto;
import com.spark.user.auth.service.AuthService;
import com.spark.user.user.dto.response.UserResponseDto;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.web.bind.annotation.PatchMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.ResponseStatus;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/v1/auth")
@RequiredArgsConstructor
@Tag(name = "인증", description = "회원 가입과 로그인")
public class AuthController {

    private final AuthService authService;

    @PostMapping("/signup")
    @ResponseStatus(HttpStatus.CREATED)
    @Operation(summary = "회원 가입", description = "데이터는 저장하지 않는다. 비밀번호는 응답에 포함하지 않는다.")
    public UserResponseDto signup(@Valid @RequestBody AuthSignupRequestDto request) {
        return authService.signup(request);
    }

    @PostMapping("/login")
    @Operation(summary = "로그인", description = "인증은 확인하지 않는다. JWT는 응답에 포함하지 않는다.")
    public UserResponseDto login(@Valid @RequestBody AuthLoginRequestDto request) {
        return authService.login(request);
    }

    @PostMapping("/social/signup")
    @ResponseStatus(HttpStatus.CREATED)
    @Operation(summary = "소셜 회원 가입", description = "데이터는 저장하지 않는다.")
    public UserResponseDto signupWithSocial(@Valid @RequestBody AuthSocialSignupRequestDto request) {
        return authService.signupWithSocial(request);
    }

    @PostMapping("/social/login")
    @Operation(summary = "소셜 로그인", description = "인증은 확인하지 않는다. JWT는 응답에 포함하지 않는다.")
    public UserResponseDto loginWithSocial(@Valid @RequestBody AuthSocialLoginRequestDto request) {
        return authService.loginWithSocial(request);
    }

    @PostMapping("/logout")
    @ResponseStatus(HttpStatus.NO_CONTENT)
    @Operation(summary = "로그아웃", description = "세션은 종료하지 않는다.")
    public void logout() {
        authService.logout();
    }

    @PostMapping("/password/reset")
    @ResponseStatus(HttpStatus.NO_CONTENT)
    @Operation(summary = "비밀번호 재설정", description = "비밀번호는 변경하지 않는다.")
    public void resetPassword(@Valid @RequestBody AuthPasswordResetRequestDto request) {
        authService.resetPassword(request);
    }

    @PatchMapping("/password")
    @ResponseStatus(HttpStatus.NO_CONTENT)
    @Operation(summary = "비밀번호 변경", description = "비밀번호는 변경하지 않는다.")
    public void updatePassword(@Valid @RequestBody AuthPasswordUpdateRequestDto request) {
        authService.updatePassword(request);
    }
}
