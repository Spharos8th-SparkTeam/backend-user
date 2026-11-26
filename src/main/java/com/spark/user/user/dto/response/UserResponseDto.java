package com.spark.user.user.dto.response;

import io.swagger.v3.oas.annotations.media.Schema;
import lombok.Builder;
import lombok.Getter;

import java.util.UUID;

@Getter
@Builder
public class UserResponseDto {

    private final UUID userId;
    private final String email;
    private final String nickname;
    private final String profileImageKey;
    private final String preferredLanguage;

    @Schema(example = "ACTIVE")
    private final String status;
}
