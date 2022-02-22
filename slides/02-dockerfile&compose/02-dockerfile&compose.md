# 02-dockerfile&compose

## docker回顾

- docker-01



TODO：介绍使用Dockerfile的目的。



## dockerfile编写

### 举个例子

```shell
mkdir mynginx
cd mynginx
vi Dockerfile
FROM nginx
RUN echo '<h1>Hi, Docker</h1>' > /usr/share/nginx/html/index.html
docker build -t nginx:mynginx .
docker run -it --rm -p8000:80 nginx:mynginx
```

### 关键字介绍

- FROM 指定命令指定基于哪个镜像创建
  - FROM指令时最重要的一个且必须为Dockerfile文件开篇的第一个非注释行，用于为镜像文件构建过程指定基准镜像，后续的指令运行在此基准镜像所提供的运行环境
  - 实践中，基准镜像可以时任何可用镜像文件，默认情况下，docker build会在docker主机上查找指定的镜像文件，在其不存在时，则会从docker hub registry上拉去所需要的镜像文件
    - 如果找不到指定的镜像文件，docker build会返回一个错误信息
  - Syntax
    - FROM <registry>[:<tag>]
      - <registry>:指定作为base image的名称
      - <tag>:base image的标签，为可选项，省略时默认为latest；
- MAINTAINER（已废弃） 设置该镜像的作者,格式：Shaokang Li <lisk@docimax.com.cn>
- LABLE：指定kv格式元数据<key>=<value>
- ENV  设置环境变量，键值对
  - 用于为镜像定义所需的环境变量，并可被Dockerfile文件中位于其后的其他指令(ENV,ADD,COPY等)所调用
  - 调用格式为$variable_name或者${variable_name}
  - Syntax:
    - ENV <key> <value>或
    - ENV <key>=<value>
    - 第一种格式中<key>之后的所有内容都会被视作<value>的组成部分，因此一次只能纸质一个变量
    - 第二种格式可以用一次设置多个变量，每个变量为一个"<key>=<vaule>"的键值对，如果value中包含空格需要用转义符转移，或者用引号标识，另外反斜线也可以用作续行
    - 定义多个变量时，建议使用第二种方式，以便再同一层完成所有功能
- VOLUME 授权访问从容器内到主机上的目录
- ADD&COPY 复制文件到容器
  - 用于从docker主机复制文件到创建的新镜像文件
  - COPY：
    - Syntax
      - COPY <src> ...<dest> 或
      - COPY ["<src>",...<dest>]
        - <src>:要复制的源文件或目录，支持使用通配符
        - <dest>:目标路径，即正在创建image的文件系统路径；建议为<dest>使用绝对路径，否则COPY指定则以WORKDIR为起始路径。
      - 注意: 在路径中有空白字符时，通常使用第二种格式
  - 文件复制准则
    - <src>必须时build上下文中的路径，不能是其父目录中的文件
    - 如果<src>是目录，则其内部文件或者子目录会被递归复制，但<src>自身不会被复制
    - 如果指定了多个<src>，或在<src>中使用了通配符，则<dest>必须是一个目录，且必须以/结尾
    - 如果<dest>事先不存在，它将会被自动创建，这包括其父目录路径
    - 49‘’分层概念？？TODO
    - 演示拷贝过程
  - ADD：
    - ADD类似于COPY指令，ADD支持使用TAR文件和URL路径
    - Syntax
      - ADD <src>...<dest>
      - ADD ["<src>"..."<dest>"]
    - 操作准则
      - 同COPY指令
      - 如果<src>为URL且<dest>不以/结尾，则<src>指定的文件将被下载并直接创建<dest>;如果<dest>以/结果，则文件名URL指定的文件将直接下载并保存为<dest>/<filename>
      - 如果<src>是本地系统上的压缩格式tar文件，它将被展开为一个目录，其行为类似于“tar -x”命令；然而，通过URL获取的tar文件不会自动展开
      - 如果<src>有多个，或其间直接使用了通配符，则<dest>必须是一个以/结尾的目录路径；如果<dest>不以/结尾，则其被视作一个普通文件，<src>的内容将被直接写入到<dest>
- WORKDIR 指定RUN/CMD/ENTRYPOINT命令的工作目录
- EXPOSE 指定容器在运行时监听的端口
- RUN 在shell或exec的环境下执行命令
  - 用于指定docker build过程中运行的应用陈旭，可以是任何指令
  - Syntax
    - RUN <command>
    - RUN ["<executable>", "<param1>", "<param2>"]
    - 第一种格式通常是一个shell命令，且以"/bin/sh -c"来运行，这意味着此进程在容器中的PID不为1，不能接受Unix信号，因此当使用docker stop <container>命令停止容器时此进程接收不到sigterm信号
    - 第二种语法格式中的参数是一个JSON格式的数组，其中executable为要运行的命令，后面则是传递给命令的选项或参数；然而，此种格式指定的命令不会以"/bin/sh -c"来发起，因此常见的shell操作如变量替换以及通配符(?,*等)替换将不会进行；不过，如果要运行的命令依赖于此shell的话可以将其替换为下面类似的格式
      - RUN ["/bin/bash", "-c", "<executable>", "<param1>"]
- CMD 容器默认的执行命令
  - 类似于RUN指令，CMD指令也可用于运行任何命令或应用程序，不过二者的运行时间点不同
    - RUN指令运行与镜像文件构建过程中，而CMD指令运行于基于Dockerfile构建出来的新镜像文件启动一个容器时
    - CMD指令的首要目的在于为启动容器指定默认的运行程序，且运行结束后，容器也将终止；CMD指定的命令也可以被docker run命令运行选项所覆盖。
    - 在Dockerfile中可以存在多个CMD指令，但是只有最后一个才会生效
    - Syntax：
      - CMD <command>
      - CMD ["<executable>", "<param1>", "<param2>"]
      - CMD ["param1", "param2"]
      - 前两种语法格式的意义同RUN
      - 第三种则用于为ENTRYPOINT指令提供默认参数
- ENTRYPOINT 配置给容器一个可执行的命令
  - 类似于CMD命令功能，用于为容器指定默认运行程序，从而使得容器像是一个单独的可执行程序
  - 与CMD不同的是，由ENTRYPOINT启动的应用程序不会被docker run命令行指定的参数所覆盖，而且，这些命令行参数会被当做参数传递给ENTRYPOINT指定的程序
    - 不过，docker run命令的--entrypoint选项可以覆盖ENTRYPOINT指令指定的程序
  - Syntax：
    - ENTRYPOINT <command>
    - ENTRYPOINT ["<executable>", "<param1>", "<param2>"]
    - docker run 命令传入的命令参数会覆盖CMD指令的内容并且附加到ENTRYPOINT命令最后作为其参数使用
    - Dockerfile文件中也可以存在多个ENTRYPOINT指令，但是只有最后一个生效

```shell
docker build -t xxx:latest -f SC.Submitthunsoft/Dockerfile . 
```

### 构建上下文

- 在执行docker build时命令最后有个点，表示当前目录，而Dockerfile就在当前目录，因此不少人以为这个路径是指Dockerfile所在路径

- 当我们进行镜像构建的时候，并非所有定制都会通过 `RUN` 指令完成，经常会需要将一些本地文件复制进镜像，比如通过 `COPY` 指令、`ADD` 指令等。而 `docker build` 命令构建镜像，其实并非在本地构建，而是在服务端，也就是 Docker 引擎中构建的。那么在这种客户端/服务端的架构中，如何才能让服务端获得本地文件呢？

  这就引入了上下文的概念。当构建的时候，用户会指定构建镜像上下文的路径，`docker build` 命令得知这个路径后，会将路径下的所有内容打包，然后上传给 Docker 引擎。这样 Docker 引擎收到这个上下文包后，展开就会获得构建镜像所需的一切文件

  

## dockerfile多阶构建

- 在Docker 17.05之前，构建Docker镜像通查采用两种方式：
  - 全部放入一个Dockerfile中，包括项目及其依赖库的编译、测试、打包等流程。带来的问题有镜像层次多，镜像体积大，部署时间长，而且有源代码泄露的风险。
  - 分散到多个Dockerfile中，事先在一个Dockerfile中将项目及其依赖库编译测试打包好，再将其拷贝到运行环境，这种方式需要编写两个Dockerfile和一些编译脚本才能将两个阶段整合起来，规避了第一种存在风险但是复杂度提升了不少。
- 在Docker 17.05开始支持了多阶段构建，使用多阶段构建我们在一个Dockerfile中处理上面所说的这些问题。
- 举例：

```shell
#See https://aka.ms/containerfastmode to understand how Visual Studio uses this Dockerfile to build your images for faster debugging.

#Depending on the operating system of the host machines(s) that will build or run the containers, the image specified in the FROM statement may need to be changed.
#For more information, please see https://aka.ms/containercompat
#EXPOSE 443

FROM mcr.microsoft.com/dotnet/aspnet:5.0-buster-slim AS base
RUN apt-get update && apt-get install -y fontconfig
COPY ["Tools/simsun.ttc", "/usr/share/fonts/"]
WORKDIR /app
EXPOSE 8051

FROM mcr.microsoft.com/dotnet/sdk:5.0-buster-slim AS build
WORKDIR /src
COPY ["generationcenter/GenerationCenter.csproj", "generationcenter/"]
COPY ["CompanyManageRepository/CompanyManageRepository.csproj", "CompanyManageRepository/"]
COPY ["ConfigMode/ConfigModel.csproj", "ConfigMode/"]
COPY ["Extensions/Extensions.csproj", "Extensions/"]
COPY ["CompanyManageApollo/CompanyManageApollo.csproj", "CompanyManageApollo/"]
COPY ["CompanyManageIRepository/CompanyManageIRepository.csproj", "CompanyManageIRepository/"]
COPY ["Help/Utility.csproj", "Help/"]
COPY ["Tools/Tools.csproj", "Tools/"]
COPY ["MysqlModel/MysqlModel.csproj", "MysqlModel/"]
COPY ["CompanyRabbitMQ/CompanyRabbitMQ.csproj", "CompanyRabbitMQ/"]
COPY ["CompanyManageWebSocket/CompanyManageWebSocket.csproj", "CompanyManageWebSocket/"]
COPY ["CompanyManageRepositoryIServices/CompanyManageRepositoryIServices.csproj", "CompanyManageRepositoryIServices/"]
COPY ["CompanyManageRepositoryServices/CompanyManageRepositoryServices.csproj", "CompanyManageRepositoryServices/"]
RUN dotnet restore "./generationcenter/GenerationCenter.csproj"
COPY . .
WORKDIR "/src/."
RUN dotnet build "generationcenter/GenerationCenter.csproj" -c Release -o /app/build

FROM build AS publish
RUN dotnet publish "generationcenter/GenerationCenter.csproj" -c Release -o /app/publish

FROM base AS final
WORKDIR /app
COPY --from=publish /app/publish .
ENTRYPOINT ["dotnet", "GenerationCenter.dll"]
```





## docker-compose编写



## Flyway使用规则

​	Prefix 可配置，前缀标识，默认值 V 表示 Versioned, R 表示 Repeatable, U 表示 Undo
​	Version 标识版本号, 由一个或多个数字构成, 数字之间的分隔符可用点 . 或下划线 _
​	Separator 可配置, 用于分隔版本标识与描述信息, 默认为两个下划线 __
​	Description 描述信息, 文字之间可以用下划线 _ 或空格 分隔
​	Suffix 可配置, 后续标识, 默认为 .sql
​	

存放问题？

​	单独放到一个项目中管理？

​	各自放到自身微服务中？

​	命名规范中要不要加上项目名称？

	1.SQL存放位置及命名规则
	??ProjectName要不要在命名中展示？？
	 Java Spring boot项目需要在项目src/main/resources/下创建db/migration目录
	 V{version}_{date}_{num}__{description}_{Author}.sql
	 仅需要被执行一次的SQL命名以大写的"V"开头，后面跟上"0~9"数字的组合,数字之间可以用“.”或者下划线"_"分割开，然后再以两个下划线分割，其后跟文件名称，最后以.sql结尾
	 举例：
		V2.1.5__create_user_ddl.sql、V4.1_2__add_user_dml.sql
	 可重复运行的SQL，则以大写的“R”开头，后面再以两个下划线分割，其后跟文件名称，最后以.sql结尾。
	 举例：
		比如，R__truncate_user_dml.sql
	
	2.Spring配置规则
	flyway:
		# 启用或禁用 flyway
		enabled: true
		# flyway 的 clean 命令会删除指定 schema 下的所有 table, 生产务必禁掉。这个默认值是 false 理论上作为默认配置是不科学的。
		clean-disabled: true
		# SQL 脚本的目录,多个路径使用逗号分隔 默认值 classpath:db/migration
		locations: classpath:db/migration
		#  metadata 版本控制信息表 默认 flyway_schema_history
		table: flyway_schema_history
		# 如果没有 flyway_schema_history 这个 metadata 表， 在执行 flyway migrate 命令之前, 必须先执行 flyway baseline 命令
		# 设置为 true 后 flyway 将在需要 baseline 的时候, 自动执行一次 baseline。
		baseline-on-migrate: true
		# 指定 baseline 的版本号,默认值为 1, 低于该版本号的 SQL 文件, migrate 时会被忽略
		baseline-version: 0
		# 字符编码 默认 UTF-8
		encoding: UTF-8
		# 是否允许不按顺序迁移 开发建议 true  生产建议 false
		out-of-order: false
		# 需要 flyway 管控的 schema list,这里我们配置为flyway  缺省的话, 使用spring.datasource.url 配置的那个 schema,
		# 可以指定多个schema, 但仅会在第一个schema下建立 metadata 表, 也仅在第一个schema应用migration sql 脚本.
		# 但flyway Clean 命令会依次在这些schema下都执行一遍. 所以 确保生产 spring.flyway.clean-disabled 为 true
		# schemas: flyway
		# 执行迁移时是否自动调用验证   当你的 版本不符合逻辑 比如 你先执行了 DML 而没有 对应的DDL 会抛出异常
		validate-on-migrate: true
	3.命令作用及注意事项
	baseline
	对已经存在数据库Schema结构的数据库一种解决方案。实现在非空数据库新建MetaData表，并把Migrations应用到该数据库；也可以在已有表结构的数据库中实现添加Metadata表。
	clean
	清除掉对应数据库Schema中所有的对象，包括表结构，视图，存储过程等，clean操作在dev 和 test阶段很好用，但在生产环境务必禁用。
	info
	用于打印所有的Migrations的详细和状态信息，也是通过MetaData和Migrations完成的，可以快速定位当前的数据库版本。
	repair
	repair操作能够修复metaData表，该操作在metadata出现错误时很有用。
	undo
	撤销操作，社区版不支持。
	validate
	验证已经apply的Migrations是否有变更，默认开启的，原理是对比MetaData表与本地Migrations的checkNum值，如果值相同则验证通过，否则失败。
	
	4. flyway docker用法：注意5.7的mysql支持7.11.3，不支持8.0的flyway会报错提示不支持
	docker run --rm -v $PWD/sql:/flyway/sql flyway/flyway:7.11.3 -url=jdbc:mysql://172.30.199.181:3307/dc_manage?createDatabaseIfNotExist=true -user=root -password=Docimax@123 migrate
	
	5. flyway注意事项
	flyway执行migrate必须在空白的数据库上进行，否则报错；
	对于已经有数据的数据库，必须先baseline，然后才能migrate；
	clean操作是删除数据库的所有内容，包括baseline之前的内容；
	尽量不要修改已经执行过的SQL，即便是R开头的可反复执行的SQL，它们会不利于数据迁移；SQL文件已经提交之后，不得修改，否则会导致校验失败
	SQL中禁止使用DROP命令，需要加创建表时的判断：CREATE TABLE IF NOT EXIST table_name...
	尽量避免使用 Undo 模式。
	
	6.参考链接：
	http://www.arccode.net/flyway-specification.html
	https://flywaydb.org/documentation/tutorials/undo
	https://www.exoscale.com/syslog/continuous-integration-databases/    https://www.fengbaichao.cn/java%E5%90%8E%E7%AB%AF/2021/11/12/%E6%95%B0%E6%8D%AE%E5%BA%93%E8%BF%81%E7%A7%BB%E5%B7%A5%E5%85%B7flyway%E7%9A%84%E4%BD%BF%E7%94%A8%E4%B8%8E%E8%AF%A6%E8%A7%A3/
	https://java.isture.com/dependencies/dbmanager/version/flyway/Flyway-commandline%E4%BD%BF%E7%94%A8.html#_1-flyway%E4%B8%8B%E8%BD%BD
> 参考文章：
>
> https://zhuanlan.zhihu.com/p/79949030
>
> https://dockerdocs.cn/develop/develop-images/dockerfile_best-practices/index.html #最佳实践
>
> https://dockerdocs.cn/compose/
>
> https://yeasy.gitbook.io/docker_practice/container/run
>
> https://yeasy.gitbook.io/docker_practice/image/build#jing-xiang-gou-jian-shang-xia-wen-context #docker build上下文介绍
>
> https://yeasy.gitbook.io/docker_practice/image/multistage-builds #dockerfile多阶构建

