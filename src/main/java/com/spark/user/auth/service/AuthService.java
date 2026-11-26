package com.spark.user.auth.service;

import com.spark.user.auth.dto.request.AuthLoginRequestDto;
import com.spark.user.auth.dto.request.AuthPasswordResetRequestDto;
import com.spark.user.auth.dto.request.AuthPasswordUpdateRequestDto;
import com.spark.user.auth.dto.request.AuthSignupRequestDto;
import com.spark.user.auth.dto.request.AuthSocialLoginRequestDto;
import com.spark.user.auth.dto.request.AuthSocialSignupRequestDto;
import com.spark.user.user.dto.response.UserResponseDto;
import org.springframework.stereotype.Service;

import java.util.UUID;

@Service
public class AuthService {

    // TODO: 회원 가입 저장 구현
    public UserResponseDto signup(AuthSignupRequestDto request) {
        return UserResponseDto.builder()
                .userId(UUID.randomUUID())
                .email(request.getEmail())
                .nickname(request.getNickname())
                .preferredLanguage(request.getPreferredLanguage())
                .status("ACTIVE")
                .build();
    }

    // TODO: 로그인 구현
    public UserResponseDto login(AuthLoginRequestDto request) {
        return UserResponseDto.builder()
                .userId(UUID.randomUUID())
                .email(request.getEmail())
                .status("ACTIVE")
                .build();
    }

    // TODO: 소셜 회원 가입 구현
    public UserResponseDto signupWithSocial(AuthSocialSignupRequestDto request) {
        return UserResponseDto.builder()
                .userId(UUID.randomUUID())
                .email(request.getEmail())
                .nickname(request.getNickname())
                .preferredLanguage(request.getPreferredLanguage())
                .status("ACTIVE")
                .build();
    }

    // TODO: 소셜 로그인 구현
    public UserResponseDto loginWithSocial(AuthSocialLoginRequestDto request) {
        return UserResponseDto.builder()
                .userId(UUID.randomUUID())
                .status("ACTIVE")
                .build();
    }

    // TODO: 로그아웃 구현
    public void logout() {
    }

    // TODO: 비밀번호 재설정 구현
    public void resetPassword(AuthPasswordResetRequestDto request) {
    }

    // TODO: 비밀번호 변경 구현
    public void updatePassword(AuthPasswordUpdateRequestDto request) {
    }
}
