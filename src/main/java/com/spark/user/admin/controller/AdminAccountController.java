package com.spark.user.admin.controller;

import com.spark.user.admin.dto.response.AdminAccountResponseDto;
import com.spark.user.admin.service.AdminAccountService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import lombok.RequiredArgsConstructor;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.UUID;

@RestController
@RequestMapping("/api/v1/admin")
@RequiredArgsConstructor
@Tag(name = "관리자", description = "관리자 계정")
public class AdminAccountController {

    private final AdminAccountService adminAccountService;

    @GetMapping("/{userId}")
    @Operation(
            summary = "회원 상세 조회",
            description = "데이터는 조회하지 않는다. userId는 회원 UUID다. 비밀번호, loginId, roleCode는 응답에 포함하지 않는다.")
    public AdminAccountResponseDto getAdminAccount(@PathVariable UUID userId) {
        return adminAccountService.getAdminAccount(userId);
    }
}
