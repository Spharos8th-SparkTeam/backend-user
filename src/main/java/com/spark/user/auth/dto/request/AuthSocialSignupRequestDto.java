package com.spark.user.auth.dto.request;

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
public class AuthSocialSignupRequestDto {

    @NotBlank
    @Pattern(regexp = "LINE|GOOGLE|X|APPLE")
    private String provider;

    @NotBlank
    @Size(max = 255)
    private String providerUserId;

    @NotBlank
    @Email
    @Size(max = 254)
    private String email;

    @NotBlank
    @Size(max = 30)
    private String nickname;

    @NotBlank
    @Pattern(regexp = "ko|en|ja|zh-CN|zh-TW")
    private String preferredLanguage;
}
