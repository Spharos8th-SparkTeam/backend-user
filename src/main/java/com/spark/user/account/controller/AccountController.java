package com.spark.user.account.controller;

import com.spark.user.account.dto.request.AccountCreateRequestDto;
import com.spark.user.account.dto.response.AccountResponseDto;
import com.spark.user.account.service.AccountService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.ResponseStatus;
import org.springframework.web.bind.annotation.RestController;

import java.util.UUID;

@RestController
@RequestMapping("/api/v1/users/{userId}/account")
@RequiredArgsConstructor
@Tag(name = "정산 계좌", description = "회원 정산 계좌")
public class AccountController {

    private final AccountService accountService;

    @GetMapping
    @Operation(summary = "정산 계좌 조회", description = "계좌번호와 암호화 키는 응답에 포함하지 않는다.")
    public AccountResponseDto getAccount(@PathVariable UUID userId) {
        return accountService.getAccount(userId);
    }

    @PostMapping
    @ResponseStatus(HttpStatus.CREATED)
    @Operation(summary = "정산 계좌 등록", description = "데이터는 저장하지 않는다. 계좌번호는 응답에 포함하지 않는다.")
    public AccountResponseDto createAccount(
            @PathVariable UUID userId,
            @Valid @RequestBody AccountCreateRequestDto request) {
        return accountService.createAccount(userId, request);
    }
}
