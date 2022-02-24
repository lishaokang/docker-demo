#/bin/sh
cat > /opt/docimax/yuntu-ofs/config/application.yml << EOF
spring:
  mvc:
    throw-exception-if-no-handler-found: true #出现错误时, 直接抛出异常
  resources:
    add-mappings: false #关闭工程中的资源文件建立映射
  jmx:
    enabled: true
  main:
    allow-bean-definition-overriding: true
  rabbitmq:
    addresses: ${MQ_IP:-172.30.199.252}:${MQ_PORT:-5672}
    username: guest
    password: guest
  cloud:
    stream:
      bindings:
        syncRequestChannel:
          destination: yuntu.ocr.sync.req
        syncCompleteChannel:
          destination: yuntu.ocr.sync.resp
          group: yuntu-ofs
          consumer:
            partitioned: true                               #true 表示启用消息分区功能
        asyncRequestChannel:
          destination: yuntu.ocr.async.req
        asyncCompleteChannel:
          destination: yuntu.ocr.async.resp
          group: yuntu-ofs
        ocrCompleteChannel:
          destination: yuntu.ocr.complete
      instance-count: 2                                     #表示消息分区的消费端节点数量为2个
      instance-index: 0                                     #该参数设置消费端实例的索引号，索引号从0开始。这里设置该节点的索引号为0

  shardingsphere:
    datasource:
      names: master
      master:
        type: com.zaxxer.hikari.HikariDataSource
        driver-class-name: com.mysql.cj.jdbc.Driver
        jdbc-url: jdbc:mysql://${MYSQL_IP:-172.30.199.252}:${MYSQL_PORT:-3306}/yuntu_ofs?useUnicode=true&characterEncoding=UTF-8&zeroDateTimeBehavior=convertToNull&autoReconnect=true
        username: root
        password: docImax1@3456
        minimum-idle: 5 # 最小空闲连接数量
        maximum-pool-size: 100 # 连接池最大连接数，默认是10
        idle-timeout: 600000 # 空闲连接存活最大时间，默认600000（10分钟）
        auto-commit: true # 此属性控制从池返回的连接的默认自动提交行为,默认值：true
        pool-name: yuntu-ofs-hikari # 连接池名字
        max-lifetime: 1800000 # 此属性控制池中连接的最长生命周期，值0表示无限生命周期，默认1800000即30分钟
        allowPoolSuspension: true #此属性支持aws的mysql故障转移
        connection-timeout: 30000 # 数据库连接超时时间,默认30秒，即30000
        connection-test-query: SELECT 1
    sharding:
      tables:
        app_ability_record:
          actual-data-nodes: master.app_ability_record_$->{0..1}
          table-strategy:
            inline:
              sharding-column: user_id
              algorithm-expression: app_ability_record_$->{user_id % 2}
          key-generator:
            column: id
            type: SNOWFLAKE
        app_ability_count:
          actual-data-nodes: master.app_ability_count_$->{0..1}
          table-strategy:
            inline:
              sharding-column: user_id
              algorithm-expression: app_ability_count_$->{user_id % 2}
          key-generator:
            column: id
            type: SNOWFLAKE
      binding-tables: app_ability_record,app_ability_count
      broadcast-tables: application,ocr_ability
    props:
      sql:
        show: false
  jpa:
    hibernate:
      ddl-auto: none
    generate-ddl: false
    open-in-view: false
    properties:
      hibernate:
        show_sql: false  # 控制台是否打印sql
        format_sql: false # 格式化打印sql语句
        use_sql_comments: false # 指出是什么操作生成了该语句
        enable_lazy_load_no_trans: true
        dialect: org.hibernate.dialect.MySQL5InnoDBDialect
  minio:
    url: http://172.30.199.252:9000
    bucket: yuntu-ocr
    access-key: admin
    secret-key: Docimax@123
#  autoconfigure:
#    exclude:
#      - com.docimax.spring.boot.minio.MinioConfiguration
#      - com.docimax.spring.boot.minio.MinioNotificationConfiguration
#      - com.docimax.spring.boot.minio.MinioMetricConfiguration

feign:
  client:
    config:
      default:
        connect-timeout: 5000
        read-timeout: 5000
        logger-level: full
  sentinel:
    enabled: true
  okhttp:
    enabled: true

# Actuator endpoints Config
## Exposes all web endpoints, default: info, health
management:
  endpoints:
    web:
      base-path: /ofs/actuator/
      exposure:
        include: "*"
  # Exposes all git info
  info:
    git:
      mode: full
  health:
    elasticsearch:
      enabled: false

logging:
  config: classpath:logback-spring.xml

mybatis-plus:
  typeAliasesPackage: com.docimax.yuntu.ofs.entity  # 搜索指定包别名，多个package用逗号或者分号分隔
  mapper-locations: classpath*:mapper/*Mapper.xml   #默认：classpath*:/mapper/**/*.xml
#  configuration:
#    log-impl: org.apache.ibatis.logging.stdout.StdOutImpl

thread:
  pool:
    ocr:
      corePoolSize: 20                        # 核心线程数
      maxPoolSize: 30                         # 最大线程数
      queueCapacity: 2000                     # 队列容量
      keepAliveSeconds: 1800                  # 线程存活时间单位（秒）
      waitForTasksToCompleteOnShutdown: true
      threadNamePrefix: ocr-                  #设置默认线程名称
    callback:
      corePoolSize: 10                        # 核心线程数
      maxPoolSize: 20                         # 最大线程数
      queueCapacity: 2000                     # 识别任务队列容量
      keepAliveSeconds: 120                   # 线程存活时间单位（秒）
      waitForTasksToCompleteOnShutdown: true
      threadNamePrefix: callback-             #设置默认线程名称
yuntu:
  gateway:
    server:
      token:
        enable: false
  cache:
    application:
      expire: 600
      refresh: 300
    ocr-ability:
      expire: 900
      refresh: 600
  file-size-limit: 5242880 #bytes
  file-storage: minio  # 文件存储方式，注意：只有整个环境中只有一台yuntu-ofs和一台yuntu-os，并且两者部署在一台主机上时，才可设置为local
  ofs:
    rate-limiter:
      enable: true   # 是否开启guava限流
      limit: 60      # 每秒允许进入的请求数量
    local-user:
      enable: false
      app[0]:
        id: 1
        appId: 70f6765c-1ca9-11ea-8388-ac1f6b645312
        appKey: 2dda74a7-83e5-41d4-b421-de3763012b26
        endTime: 2020-09-30
        priority: 6
        userId: 1
      app[1]:
        id: 2
        appId: AB56A6F9-B796-4F14-982F-117BDF658C60
        appKey: 87c5e888-8cb1-4292-b89c-35e04b72243e
        endTime: 2030-09-30
        priority: 6
        userId: 2
      ability[0]:
        id: 35
        code: 1001
        createPdf: true
    local-file-keep: 7
    db-record-keep: 60
    cron:
      del-local-file: 0 0 1 * * ?  # 每天凌晨1点删除 local-file-cache 天前的文件
      del-db-record: 0 30 1 * * ?  # 每天凌晨1:30删除 db-record-keep 天前的识别记录
file:
  path: /opt/docimax/data
  ocr:
    src: /opt/docimax/data/src
    temp: /opt/docimax/data/temp
    dst: /opt/docimax/data/dst
okhttp:
  timeout: 5000           #超时时间
  maxConnection: 50       #最大连接数
  coreConnection: 10      #核心连接数
  resetConnection: false  #是否重试
  maxHostConnection: 10   #单域名最大线程数
EOF

exec "$@"
