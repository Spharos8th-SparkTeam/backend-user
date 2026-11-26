package com.spark.user.admin.dto.response;

import io.swagger.v3.oas.annotations.media.Schema;
import lombok.Builder;
import lombok.Getter;

import java.time.LocalDateTime;
import java.util.UUID;

@Getter
@Builder
public class AdminAccountResponseDto {

    private final UUID userId;
    private final String email;
    private final String nickname;
    private final String profileImageKey;
    private final String preferredLanguage;

    @Schema(example = "ACTIVE")
    private final String status;

    private final LocalDateTime emailVerifiedAt;
    private final LocalDateTime suspendedUntil;
    private final LocalDateTime withdrawnAt;
    private final LocalDateTime createdAt;
    private final LocalDateTime updatedAt;
}
