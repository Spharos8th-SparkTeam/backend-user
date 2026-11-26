package com.spark.user.admin.dto.response;

import io.swagger.v3.oas.annotations.media.Schema;
import lombok.Builder;
import lombok.Getter;

import java.util.UUID;

@Getter
@Builder
public class AdminAccountResponseDto {

    private final UUID adminId;
    private final String loginId;
    private final String email;
    private final String roleCode;

    @Schema(example = "ACTIVE")
    private final String status;
}
