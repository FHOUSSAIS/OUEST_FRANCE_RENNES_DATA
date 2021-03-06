SET ANSI_NULLS OFF
SET QUOTED_IDENTIFIER OFF

-----------------------------------------------------------------------------------------
-- Procédure		: CFG_PARAMETRE
-- Paramètre d'entrée	: @v_par_nom : Paramètre
--						  @v_par_val : Valeur
--						  @v_server1 : Instance serveur 1
--						  @v_server2 : Instance serveur 2
--						  @v_proxy_account : Compte proxy du serveur
--						  @v_password : Mot de passe
-- Paramètre de sortie	: @v_retour : Code de retour
-- Descriptif		: Gestion des paramètres
-----------------------------------------------------------------------------------------

CREATE PROCEDURE [dbo].[CFG_PARAMETRE]
	@v_par_nom varchar(16),
	@v_par_val varchar(128),
	@v_server1 varchar(max),
	@v_server2 varchar(max),
	@v_proxy_account varchar(max),
	@v_password varchar(max),
	@v_suffix varchar(max),
	@v_retour smallint out
AS

IF 1 = 0
BEGIN
	-- This line will be executed if FMTONLY was initially set to ON
	SET FMTONLY OFF
	RETURN
END

DECLARE
	@v_error int,
	@v_sql nvarchar(4000),
	@v_params nvarchar(32),
	@v_bdd_data sysname,
	@v_mirror_instance varchar(max)
	
	SET @v_retour = 113
	SET @v_error = 0
	IF EXISTS (SELECT 1 FROM PARAMETRE WHERE PAR_NOM = @v_par_nom)
	BEGIN
		SET @v_retour = 0
		IF @v_par_nom = 'MIRRORING'
		BEGIN
			SET @v_bdd_data = DB_NAME()
			IF @v_server1 = @@SERVERNAME
				SET @v_mirror_instance = @v_server2
			ELSE
				SET @v_mirror_instance = @v_server1
			IF @v_par_val = 1
			BEGIN
				UPDATE PARAMETRE SET PAR_VAL = @v_suffix WHERE PAR_NOM = 'DNSSUFFIX'
				SET @v_error = @@ERROR				
				IF @v_error = 0
				BEGIN
					EXEC @v_retour = CFG_MIROIR 0, @v_server1, @v_server2, @v_proxy_account, @v_password
					SET @v_error = @@ERROR
					IF ((@v_retour = 0) AND (@v_error = 0))
					BEGIN
						SET @v_sql = 'IF EXISTS (SELECT 1 FROM sys.databases WHERE name = ''''' + DB_NAME() + ''''' AND state = 2)
								ALTER DATABASE ' + DB_NAME() + ' SET PARTNER OFF
						IF EXISTS (SELECT 1 FROM sys.databases WHERE name = ''''' + DB_NAME() + ''''' AND state = 1)
							RESTORE DATABASE ' + DB_NAME() + ' WITH RECOVERY'
						SET @v_sql = 'EXEC (''' + @v_sql + ''') AT [' + @v_mirror_instance + ']'
						EXEC (@v_sql)
						SET @v_error = @@ERROR
						IF @v_error = 0
						BEGIN
							SET @v_sql = N'EXEC @v_retour = [' + @v_mirror_instance + '].' + @v_bdd_data + '.dbo.CFG_MIROIR 0, "' + @v_server1 + '", "' + @v_server2 + '", ''' + @v_proxy_account + ''', ''' + @v_password + ''''
							SET @v_params = '@v_retour int out'
							EXEC sp_executesql @v_sql, @v_params, @v_retour out
							SET @v_error = @@ERROR
							IF ((@v_retour = 0) AND (@v_error = 0))
							BEGIN
								EXEC @v_retour = CFG_MIROIR 1, @v_server1, @v_server2, NULL, NULL
								SET @v_error = @@ERROR
								IF ((@v_retour = 0) AND (@v_error = 0))
								BEGIN
									SET @v_sql = N'EXEC @v_retour = [' + @v_mirror_instance + '].' + @v_bdd_data + '.dbo.CFG_MIROIR 1, "' + @v_server1 + '", "' + @v_server2 + '", NULL, NULL'
									SET @v_params = '@v_retour int out'
									EXEC sp_executesql @v_sql, @v_params, @v_retour out
									SET @v_error = @@ERROR
								END
							END
						END
					END
				END
			END
		END
		IF ((@v_retour = 0) AND (@v_error = 0)
			AND NOT EXISTS (SELECT 1 FROM PARAMETRE WHERE PAR_NOM = @v_par_nom AND PAR_VAL = @v_par_val))
		BEGIN	
			BEGIN TRAN
			IF @v_par_nom = 'MIRRORING'
			BEGIN
				IF @v_par_val = 1
				BEGIN
					UPDATE VOYANT SET VYT_ACTIF = 1 WHERE VYT_ID = 4
					SET @v_error = @@ERROR
					IF @v_error = 0
					BEGIN
						UPDATE OPERATION SET OPE_VISIBLE = 1 WHERE OPE_ID IN (2, 3, 35)
						SET @v_error = @@ERROR
						IF @v_error = 0
						BEGIN
							IF NOT EXISTS (SELECT 1 FROM ASSOCIATION_OPERATION_GROUPE, GROUPE WHERE AOG_OPERATION = 2 AND GRP_ID = AOG_GROUPE AND GRP_ADMINISTRATEUR = 1)
							BEGIN
								INSERT INTO ASSOCIATION_OPERATION_GROUPE (AOG_GROUPE, AOG_OPERATION) SELECT GRP_ID, 2 FROM GROUPE WHERE GRP_ADMINISTRATEUR = 1
								SET @v_error = @@ERROR
							END
							IF @v_error = 0
							BEGIN
								IF NOT EXISTS (SELECT 1 FROM ASSOCIATION_OPERATION_GROUPE, GROUPE WHERE AOG_OPERATION = 3 AND GRP_ID = AOG_GROUPE AND GRP_ADMINISTRATEUR = 1)
								BEGIN
									INSERT INTO ASSOCIATION_OPERATION_GROUPE (AOG_GROUPE, AOG_OPERATION) SELECT GRP_ID, 3 FROM GROUPE WHERE GRP_ADMINISTRATEUR = 1
									SET @v_error = @@ERROR
									IF @v_error = 0
									BEGIN
										IF NOT EXISTS (SELECT 1 FROM ASSOCIATION_OPERATION_GROUPE, GROUPE WHERE AOG_OPERATION = 35 AND GRP_ID = AOG_GROUPE AND GRP_ADMINISTRATEUR = 1)
										BEGIN
											INSERT INTO ASSOCIATION_OPERATION_GROUPE (AOG_GROUPE, AOG_OPERATION) SELECT GRP_ID, 35 FROM GROUPE WHERE GRP_ADMINISTRATEUR = 1
											SET @v_error = @@ERROR
										END
										IF @v_error = 0
											SET @v_retour = 0
									END
								END
							END
						END
					END
				END
				ELSE IF @v_par_val = 0
				BEGIN
					DELETE ASSOCIATION_OPERATION_GROUPE WHERE AOG_OPERATION IN (2, 3, 35)
					SET @v_error = @@ERROR
					IF @v_error = 0
					BEGIN
						UPDATE OPERATION SET OPE_VISIBLE = 0 WHERE OPE_ID IN (2, 3, 35)
						SET @v_error = @@ERROR
						IF @v_error = 0
						BEGIN
							UPDATE VOYANT SET VYT_ACTIF = 0 WHERE VYT_ID = 4
							SET @v_error = @@ERROR
							IF @v_error = 0
								SET @v_retour = 0
						END
					END
				END
			END
			ELSE IF @v_par_nom = 'ATT_AUTORISATION'
			BEGIN
				IF @v_par_val = 1
				BEGIN
					UPDATE VOYANT SET VYT_ACTIF = 1 WHERE VYT_ID = 3
					SET @v_error = @@ERROR
					IF @v_error = 0
					BEGIN
						UPDATE OPERATION SET OPE_VISIBLE = 1 WHERE OPE_ID IN (30, 28)
						SET @v_error = @@ERROR
						IF @v_error = 0
						BEGIN
							IF NOT EXISTS (SELECT 1 FROM ASSOCIATION_OPERATION_GROUPE, GROUPE WHERE AOG_OPERATION = 30 AND GRP_ID = AOG_GROUPE AND GRP_ADMINISTRATEUR = 1)
							BEGIN
								INSERT INTO ASSOCIATION_OPERATION_GROUPE (AOG_GROUPE, AOG_OPERATION) SELECT GRP_ID, 30 FROM GROUPE WHERE GRP_ADMINISTRATEUR = 1
								SET @v_error = @@ERROR
							END
							IF @v_error = 0
							BEGIN
								IF NOT EXISTS (SELECT 1 FROM ASSOCIATION_OPERATION_GROUPE, GROUPE WHERE AOG_OPERATION = 28 AND GRP_ID = AOG_GROUPE AND GRP_ADMINISTRATEUR = 1)
								BEGIN
									INSERT INTO ASSOCIATION_OPERATION_GROUPE (AOG_GROUPE, AOG_OPERATION) SELECT GRP_ID, 28 FROM GROUPE WHERE GRP_ADMINISTRATEUR = 1
									SET @v_error = @@ERROR
								END
								IF @v_error = 0
									SET @v_retour = 0
							END
						END
					END
				END
				ELSE IF @v_par_val = 0
				BEGIN
					DELETE ASSOCIATION_OPERATION_GROUPE WHERE AOG_OPERATION IN (30, 28)
					SET @v_error = @@ERROR
					IF @v_error = 0
					BEGIN
						UPDATE OPERATION SET OPE_VISIBLE = 0 WHERE OPE_ID IN (30, 28)
						SET @v_error = @@ERROR
						IF @v_error = 0
						BEGIN
							UPDATE VOYANT SET VYT_ACTIF = 0 WHERE VYT_ID = 3
							SET @v_error = @@ERROR
							IF @v_error = 0
								SET @v_retour = 0
						END
					END
				END
			END
			IF @v_retour = 0
			BEGIN
				UPDATE PARAMETRE SET PAR_VAL = @v_par_val WHERE PAR_NOM = @v_par_nom
				SET @v_error = @@ERROR
			END
			IF @v_error <> 0
				ROLLBACK TRAN
			ELSE
			BEGIN
				COMMIT TRAN
				IF @v_par_nom = 'MIRRORING'
				BEGIN
					IF @v_par_val = 0
					BEGIN
						EXEC @v_retour = INT_SETMIROIR 0
						SET @v_error = @@ERROR
						EXEC @v_retour = CFG_MIROIR 2, @v_server1, @v_server2, NULL, NULL
						SET @v_error = @@ERROR
						IF ((@v_retour = 0) AND (@v_error = 0))
						BEGIN
							IF EXISTS (SELECT 1 FROM master.sys.servers WHERE name = @v_mirror_instance)
							BEGIN
								SET @v_sql = N'EXEC @v_retour = [' + @v_mirror_instance + '].' + @v_bdd_data + '.dbo.CFG_MIROIR 2, "' + @v_server1 + '", "' + @v_server2 + '", NULL, NULL'
								SET @v_params = '@v_retour int out'
								EXEC sp_executesql @v_sql, @v_params, @v_retour out
								SET @v_error = @@ERROR
								IF @v_error = 0
								BEGIN
									SET @v_sql = N'EXEC @v_retour = [' + @v_mirror_instance + '].' + @v_bdd_data + '.dbo.CFG_MIROIR 3, "' + @v_server1 + '", "' + @v_server2 + '", NULL, NULL'
									SET @v_params = '@v_retour int out'
									EXEC sp_executesql @v_sql, @v_params, @v_retour out
									SET @v_error = @@ERROR
								END
							END
							IF @v_error = 0
							BEGIN
								EXEC @v_retour = CFG_MIROIR 3, @v_server1, @v_server2, NULL, NULL
								SET @v_error = @@ERROR
								IF @v_error = 0
									SET @v_retour = 0
							END
						END
					END
				END
			END
		END
	END
	RETURN @v_error

