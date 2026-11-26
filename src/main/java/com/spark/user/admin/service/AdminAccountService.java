package com.spark.user.admin.service;

import com.spark.user.admin.dto.response.AdminAccountResponseDto;
import org.springframework.stereotype.Service;

import java.util.UUID;

@Service
public class AdminAccountService {

    // TODO: 관리자 조회 구현
    public AdminAccountResponseDto getAdminAccount(UUID userId) {
        return AdminAccountResponseDto.builder()
                .adminId(userId)
                .build();
    }
}
