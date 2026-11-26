package com.spark.user.user.dto.request;

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
public class UserUpdateRequestDto {

    @Size(max = 30)
    private String nickname;

    @Size(max = 255)
    private String profileImageKey;

    @Pattern(regexp = "ko|en|ja|zh-CN|zh-TW")
    private String preferredLanguage;
}
