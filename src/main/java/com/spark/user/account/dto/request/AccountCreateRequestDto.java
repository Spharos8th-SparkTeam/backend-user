package com.spark.user.account.dto.request;

import com.fasterxml.jackson.annotation.JsonProperty;
import io.swagger.v3.oas.annotations.media.Schema;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;
import lombok.AllArgsConstructor;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
public class AccountCreateRequestDto {

    @NotBlank
    @Size(max = 100)
    private String holderName;

    @NotBlank
    @Size(max = 100)
    private String bankName;

    @NotBlank
    @Size(max = 20)
    private String bankCode;

    @NotBlank
    @JsonProperty(access = JsonProperty.Access.WRITE_ONLY)
    @Schema(
            description = "계좌번호. 저장 시 암호문만 두고 응답에는 포함하지 않는다.",
            accessMode = Schema.AccessMode.WRITE_ONLY)
    private String accountNumber;

    @NotNull
    private Boolean defaultAccount;
}
