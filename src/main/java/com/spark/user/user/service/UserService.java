package com.spark.user.user.service;

import com.spark.user.user.dto.request.UserUpdateRequestDto;
import com.spark.user.user.dto.response.UserResponseDto;
import org.springframework.stereotype.Service;

import java.util.UUID;

@Service
public class UserService {

    // TODO: 회원 조회 구현
    public UserResponseDto getUser(UUID userId) {
        return UserResponseDto.builder()
                .userId(userId)
                .build();
    }

    // TODO: 회원 수정 구현
    public UserResponseDto updateUser(UUID userId, UserUpdateRequestDto request) {
        return UserResponseDto.builder()
                .userId(userId)
                .nickname(request.getNickname())
                .profileImageKey(request.getProfileImageKey())
                .preferredLanguage(request.getPreferredLanguage())
                .build();
    }

    // TODO: 회원 탈퇴 구현
    public void deleteUser(UUID userId) {
    }
}
