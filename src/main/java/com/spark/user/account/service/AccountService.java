package com.spark.user.account.service;

import com.spark.user.account.dto.request.AccountCreateRequestDto;
import com.spark.user.account.dto.response.AccountResponseDto;
import org.springframework.stereotype.Service;

import java.util.UUID;

@Service
public class AccountService {

    // TODO: 정산 계좌 조회 구현
    public AccountResponseDto getAccount(UUID userId) {
        return AccountResponseDto.builder()
                .userId(userId)
                .build();
    }

    // TODO: 계좌번호 암호화 후 저장 구현
    public AccountResponseDto createAccount(UUID userId, AccountCreateRequestDto request) {
        return AccountResponseDto.builder()
                .accountId(UUID.randomUUID())
                .userId(userId)
                .holderName(request.getHolderName())
                .bankName(request.getBankName())
                .bankCode(request.getBankCode())
                .defaultAccount(request.getDefaultAccount())
                .build();
    }
}
