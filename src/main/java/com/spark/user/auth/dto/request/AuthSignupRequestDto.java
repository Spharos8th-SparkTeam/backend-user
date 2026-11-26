package com.spark.user.auth.dto.request;

import com.fasterxml.jackson.annotation.JsonProperty;
import io.swagger.v3.oas.annotations.media.Schema;
import jakarta.validation.Valid;
import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotEmpty;
import jakarta.validation.constraints.Pattern;
import jakarta.validation.constraints.Size;
import lombok.AllArgsConstructor;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

import java.util.List;

@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
public class AuthSignupRequestDto {

    @NotBlank
    @Email
    @Size(max = 254)
    private String email;

    @NotBlank
    @Size(max = 30)
    private String nickname;

    @NotBlank
    @JsonProperty(access = JsonProperty.Access.WRITE_ONLY)
    @Schema(description = "비밀번호. 응답에 포함하지 않는다.", accessMode = Schema.AccessMode.WRITE_ONLY)
    private String password;

    @NotBlank
    @Pattern(regexp = "ko|en|ja|zh-CN|zh-TW")
    private String preferredLanguage;

    @NotEmpty
    @Valid
    private List<TermsAgreementRequestDto> agreements;
}
