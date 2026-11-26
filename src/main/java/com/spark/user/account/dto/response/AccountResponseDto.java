package com.spark.user.account.dto.response;

import lombok.Builder;
import lombok.Getter;

import java.util.UUID;

@Getter
@Builder
public class AccountResponseDto {

    private final UUID accountId;
    private final UUID userId;
    private final String holderName;
    private final String bankName;
    private final String bankCode;
    private final Boolean defaultAccount;
}
