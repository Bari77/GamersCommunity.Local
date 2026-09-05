-- AuthZ applicative (hors IdP). À appliquer sur la base GamersCommunity.
-- Site / jeu / groupe : rôles stockés ici, pas dans Authentik.

IF DB_ID(N'GamersCommunity') IS NULL
BEGIN
    CREATE DATABASE GamersCommunity;
END
GO

USE GamersCommunity;
GO

IF OBJECT_ID(N'dbo.SiteRoles', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.SiteRoles (
        Id INT NOT NULL IDENTITY(1,1) CONSTRAINT PK_SiteRoles PRIMARY KEY,
        Code NVARCHAR(50) NOT NULL,
        CONSTRAINT UQ_SiteRoles_Code UNIQUE (Code)
    );

    INSERT INTO dbo.SiteRoles (Code) VALUES (N'admin'), (N'moderator'), (N'member');
END
GO

IF OBJECT_ID(N'dbo.UserSiteRoles', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.UserSiteRoles (
        IdUser INT NOT NULL,
        IdSiteRole INT NOT NULL,
        CONSTRAINT PK_UserSiteRoles PRIMARY KEY (IdUser, IdSiteRole),
        CONSTRAINT FK_UserSiteRoles_Users FOREIGN KEY (IdUser) REFERENCES dbo.Users (Id),
        CONSTRAINT FK_UserSiteRoles_SiteRoles FOREIGN KEY (IdSiteRole) REFERENCES dbo.SiteRoles (Id)
    );
END
GO

IF OBJECT_ID(N'dbo.GameRoles', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.GameRoles (
        Id INT NOT NULL IDENTITY(1,1) CONSTRAINT PK_GameRoles PRIMARY KEY,
        IdGame INT NOT NULL,
        Code NVARCHAR(50) NOT NULL,
        CONSTRAINT UQ_GameRoles_Game_Code UNIQUE (IdGame, Code)
    );
END
GO

IF OBJECT_ID(N'dbo.UserGameRoles', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.UserGameRoles (
        IdUser INT NOT NULL,
        IdGameRole INT NOT NULL,
        CONSTRAINT PK_UserGameRoles PRIMARY KEY (IdUser, IdGameRole),
        CONSTRAINT FK_UserGameRoles_Users FOREIGN KEY (IdUser) REFERENCES dbo.Users (Id),
        CONSTRAINT FK_UserGameRoles_GameRoles FOREIGN KEY (IdGameRole) REFERENCES dbo.GameRoles (Id)
    );
END
GO

IF OBJECT_ID(N'dbo.GroupRoles', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.GroupRoles (
        Id INT NOT NULL IDENTITY(1,1) CONSTRAINT PK_GroupRoles PRIMARY KEY,
        Code NVARCHAR(50) NOT NULL,
        CONSTRAINT UQ_GroupRoles_Code UNIQUE (Code)
    );

    INSERT INTO dbo.GroupRoles (Code) VALUES (N'owner'), (N'admin'), (N'moderator'), (N'member');
END
GO

IF OBJECT_ID(N'dbo.UserGroupRoles', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.UserGroupRoles (
        IdUser INT NOT NULL,
        IdGroup INT NOT NULL,
        IdGroupRole INT NOT NULL,
        CONSTRAINT PK_UserGroupRoles PRIMARY KEY (IdUser, IdGroup),
        CONSTRAINT FK_UserGroupRoles_Users FOREIGN KEY (IdUser) REFERENCES dbo.Users (Id),
        CONSTRAINT FK_UserGroupRoles_GroupRoles FOREIGN KEY (IdGroupRole) REFERENCES dbo.GroupRoles (Id)
    );
END
GO
