package com.fenglin.springboottest.config;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Configuration;
import org.springframework.web.servlet.config.annotation.ResourceHandlerRegistry;
import org.springframework.web.servlet.config.annotation.WebMvcConfigurer;

import java.io.File;

/**
 * Web 静态资源映射。
 *
 * <p>时光档案上传的照片保存在磁盘目录（由 application.properties 的 file.upload-dir 指定，
 * 默认 ./uploads），不在 classpath 内，Spring Boot 默认不会托管它们。
 * 这里把 /uploads/** 映射到该目录，使上传后的照片可以通过 HTTP 真正访问到，
 * 否则前端回填的 /uploads/archives/xxx.png 永远 404、照片显示不出来。</p>
 *
 * <p>注意：只新增了一个资源处理器，不影响 Boot 默认的 /static、/webjars 等静态资源。</p>
 */
@Configuration
public class WebConfig implements WebMvcConfigurer {

    @Value("${file.upload-dir:./uploads}")
    private String uploadDir;

    @Override
    public void addResourceHandlers(ResourceHandlerRegistry registry) {
        // 解析为绝对路径，避免工作目录不同导致映射错位
        String absDir = new File(uploadDir).getAbsolutePath();
        if (!absDir.endsWith("/")) {
            absDir += "/";
        }
        registry.addResourceHandler("/uploads/**")
                .addResourceLocations("file:" + absDir);
    }
}
