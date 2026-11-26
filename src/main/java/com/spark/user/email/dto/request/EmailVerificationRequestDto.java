package com.spark.user.email.dto.request;

import com.fasterxml.jackson.annotation.JsonProperty;
import io.swagger.v3.oas.annotations.media.Schema;
import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Pattern;
import jakarta.validation.constraints.Size;
import lombok.AllArgsConstructor;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
public class EmailVerificationRequestDto {

    @NotBlank
    @Email
    @Size(max = 254)
    private String email;

    @NotBlank
    @Pattern(regexp = "SIGNUP|PASSWORD_RESET|PASSWORD_CHANGE|WITHDRAW")
    private String purpose;

    @JsonProperty(access = JsonProperty.Access.WRITE_ONLY)
    @Schema(
            description = "인증번호. 확인 요청에만 넣고 응답에는 포함하지 않는다.",
            accessMode = Schema.AccessMode.WRITE_ONLY)
    private String verificationCode;
}
