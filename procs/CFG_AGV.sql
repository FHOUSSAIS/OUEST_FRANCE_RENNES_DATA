SET ANSI_NULLS OFF
SET QUOTED_IDENTIFIER OFF


-----------------------------------------------------------------------------------------
-- Procédure		: CFG_AGV
-- Paramètre d'entrées	: @v_action : Action  à mener
--			  @v_ssaction : Sous action à mener
--			  @v_iag_id : Identifiant AGV
--			  @v_tag_id : Identifiant type AGV
--			  @v_lib_libelle : Libellé
--			  @v_lan_id : Identifiant langue
-- Paramètre de sorties	: @v_retour : Code de retour
--			  @v_tra_id : Identifiant traduction
-- Descriptif		: Gestion des AGVs
-----------------------------------------------------------------------------------------

CREATE PROCEDURE [dbo].[CFG_AGV]
	@v_action smallint,
	@v_ssaction smallint,
	@v_iag_id tinyint,
	@v_tag_id tinyint,
	@v_tra_id int out,
	@v_iag_libelle varchar(8000),
	@v_lan_id varchar(3),
	@v_retour smallint out
AS

IF 1 = 0
BEGIN
	-- This line will be executed if FMTONLY was initially set to ON
	SET FMTONLY OFF
	RETURN
END

DECLARE
	@v_error smallint,
	@v_local bit,
	@v_tag_outil tinyint,
	@v_tag_profondeur tinyint,
	@v_tag_niveau tinyint,
	@v_tag_colonne tinyint,
	@v_bas_systeme bigint,
	@v_bas_base bigint,
	@v_mod_id int,
	@v_p tinyint,
	@v_n tinyint,
	@v_c tinyint,
	@v_lib_libelle varchar(128),
	@v_adr_idtraduction int,
	@v_adr_sousbase bigint
	
	IF @@TRANCOUNT > 0
		SET @v_local = 0
	ELSE
	BEGIN
		SET @v_local = 1
		BEGIN TRAN AGV
	END
	SET @v_retour = 113
	SET @v_error = 0
	IF @v_action = 0
	BEGIN
		IF EXISTS (SELECT 1 FROM SYSTEME)
		BEGIN
			IF NOT EXISTS (SELECT 1 FROM INFO_AGV WHERE IAG_ID = @v_iag_id)
				AND NOT EXISTS (SELECT 1 FROM INFO_AGV, LIBELLE WHERE LIB_TRADUCTION = IAG_IDTRADUCTION AND LIB_LIBELLE = @v_iag_libelle)
			BEGIN
				EXEC @v_error = LIB_TRADUCTION @v_action, @v_lan_id, @v_iag_libelle, @v_tra_id out
				IF @v_error = 0
				BEGIN
					SELECT TOP 1 @v_mod_id = MOD_IDMODE FROM MODE_EXPLOITATION WHERE MOD_SYSTEME = 0 ORDER BY MOD_IDMODE DESC
					INSERT INTO INFO_AGV (IAG_ID, IAG_POS_X, IAG_POS_Y, IAG_POS_THETA, IAG_ENCHARGE, IAG_TAUXBATTERIE, IAG_MODE_EXPLOIT, IAG_TYPE, IAG_IDTRADUCTION,
						IAG_VALID_SPV, IAG_VALID_PLT, IAG_SERVICE, IAG_CIRCUIT, IAG_MODE, IAG_INITIALISATION, IAG_DECHARGE, IAG_PAUSE,
						IAG_LIMITATIONVITESSE, IAG_VITESSEMAXIMALE, IAG_ARRETDISTANCE, IAG_VITESSENULLE, IAG_IDPOINTARRET, IAG_ARRETPOINTARRET, IAG_MOTIFARRETDISTANCE,
						IAG_HORAMETRE, IAG_ARRETCONFLIT, IAG_MAINTENANCE)
						VALUES (@v_iag_id, 0, 0, 0, 0, 0, @v_mod_id, @v_tag_id, @v_tra_id, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0)
					SET @v_error = @@ERROR
					IF @v_error = 0
					BEGIN
						UPDATE MODE_EXPLOITATION SET MOD_NBAGVMAX = MOD_NBAGVMAX + 1 WHERE MOD_IDMODE = 1
						SET @v_error = @@ERROR
						IF @v_error = 0
						BEGIN
							INSERT INTO INTERACTION (INR_DE, INR_VERS, INR_TYPE) SELECT A.IAG_ID, B.IAG_ID, 0 FROM INFO_AGV A, INFO_AGV B WHERE A.IAG_ID <> B.IAG_ID AND ((A.IAG_ID = @v_iag_id) OR (B.IAG_ID = @v_iag_id))
							SET @v_error = @@ERROR
							IF @v_error = 0
							BEGIN
								SELECT TOP 1 @v_bas_systeme = SYS_SYSTEME FROM SYSTEME
								SET @v_bas_base = dbo.INT_GETIDBASE(1, @v_iag_id, 1, 1, 1, 1)
								INSERT INTO BASE (BAS_SYSTEME, BAS_BASE, BAS_TYPE_MAGASIN, BAS_MAGASIN, BAS_ALLEE, BAS_COULOIR, BAS_COTE, BAS_RACK,
									BAS_TYPE, BAS_IDTRADUCTION, BAS_LIBELLE_VISIBLE, BAS_VISIBLE)
									VALUES (@v_bas_systeme, @v_bas_base, 1, @v_iag_id, 1, 1, 1, 1, 1, @v_tra_id, 0, 1)
								SET @v_error = @@ERROR
								IF @v_error = 0
									EXEC @v_error = CFG_AGV 1, 1, @v_iag_id, @v_tag_id, NULL, @v_iag_libelle, @v_lan_id, @v_retour out
							END
						END
						IF ((@v_error = 0) AND (@v_retour = 0))
							SET @v_retour = 0
					END
				END
			END
			ELSE
				SET @v_retour = 117
		END
		ELSE
			SET @v_retour = 1284
	END
	IF @v_action = 1
	BEGIN
		IF @v_ssaction = 0
		BEGIN
			IF NOT EXISTS (SELECT 1 FROM INFO_AGV, LIBELLE WHERE LIB_TRADUCTION = IAG_IDTRADUCTION AND LIB_LIBELLE = @v_iag_libelle)
			BEGIN
				UPDATE LIBELLE SET LIB_LIBELLE = @v_iag_libelle WHERE LIB_LANGUE = @v_lan_id AND LIB_TRADUCTION = @v_tra_id
				SET @v_error = @@ERROR
				IF @v_error = 0
				BEGIN
					DECLARE c_adresse CURSOR LOCAL FOR SELECT ADR_IDTRADUCTION, ADR_PROFONDEUR, ADR_NIVEAU, ADR_COLONNE
						FROM BASE INNER JOIN ADRESSE ON ADR_SYSTEME = BAS_SYSTEME AND ADR_BASE = BAS_BASE
						WHERE BAS_TYPE_MAGASIN = 1 AND BAS_MAGASIN = @v_iag_id
					OPEN c_adresse
					FETCH NEXT FROM c_adresse INTO @v_adr_idtraduction, @v_p, @v_n, @v_c
					WHILE ((@@FETCH_STATUS = 0) AND (@v_error = 0))
					BEGIN
						UPDATE LIBELLE SET LIB_LIBELLE = @v_iag_libelle + '-' + CONVERT(varchar, @v_p) + '.' + CONVERT(varchar, @v_n) + '.' + CONVERT(varchar, @v_c)
							WHERE LIB_LANGUE = @v_lan_id AND LIB_TRADUCTION = @v_adr_idtraduction
						SET @v_error = @@ERROR
						FETCH NEXT FROM c_adresse INTO @v_adr_idtraduction, @v_p, @v_n, @v_c
					END
					CLOSE c_adresse
					DEALLOCATE c_adresse
					IF @v_error = 0
						SET @v_retour = 0
				END
			END
			ELSE
				SET @v_retour = 117
		END
		ELSE IF @v_ssaction = 1
		BEGIN
			SELECT @v_bas_systeme = BAS_SYSTEME, @v_bas_base = BAS_BASE FROM BASE WHERE BAS_TYPE_MAGASIN = 1 AND BAS_MAGASIN = @v_iag_id
			SELECT @v_tag_outil = TAG_OUTIL, @v_tag_profondeur = TAG_PROFONDEUR, @v_tag_niveau = TAG_NIVEAU,
				@v_tag_colonne = TAG_COLONNE FROM TYPE_AGV WHERE TAG_ID = @v_tag_id
			IF NOT EXISTS (SELECT 1 FROM CHARGE INNER JOIN ADRESSE ON ADR_SYSTEME = CHG_ADR_KEYSYS AND ADR_BASE = CHG_ADR_KEYBASE AND ADR_SOUSBASE = CHG_ADR_KEYSSBASE
				INNER JOIN BASE ON BAS_SYSTEME = ADR_SYSTEME AND BAS_BASE = ADR_BASE WHERE BAS_TYPE_MAGASIN = 1 AND BAS_MAGASIN = @v_iag_id
				AND ((ADR_PROFONDEUR > @v_tag_profondeur) OR (ADR_NIVEAU > @v_tag_niveau) OR (ADR_COLONNE > @v_tag_colonne * @v_tag_outil)))
			BEGIN
				DELETE OUTIL_AGV WHERE OUA_IDAGV = @v_iag_id AND OUA_COLONNE > @v_tag_outil
				SET @v_error = @@ERROR
				IF @v_error = 0
				BEGIN
					DECLARE c_adresse CURSOR LOCAL FOR SELECT BAS_SYSTEME, BAS_BASE, ADR_SOUSBASE, ADR_IDTRADUCTION
						FROM ADRESSE INNER JOIN BASE ON BAS_SYSTEME = ADR_SYSTEME AND BAS_BASE = ADR_BASE WHERE BAS_TYPE_MAGASIN = 1 AND BAS_MAGASIN = @v_iag_id
						AND ((ADR_PROFONDEUR > @v_tag_profondeur) OR (ADR_NIVEAU > @v_tag_niveau)
						OR (ADR_COLONNE > @v_tag_colonne * @v_tag_outil))
					OPEN c_adresse
					FETCH NEXT FROM c_adresse INTO @v_bas_systeme, @v_bas_base, @v_adr_sousbase, @v_adr_idtraduction
					WHILE ((@@FETCH_STATUS = 0) AND (@v_error = 0))
					BEGIN
						DELETE ADRESSE WHERE ADR_SYSTEME = @v_bas_systeme AND ADR_BASE = @v_bas_base AND ADR_SOUSBASE = @v_adr_sousbase
						SET @v_error = @@ERROR
						IF @v_error = 0
							EXEC @v_error = LIB_TRADUCTION @v_action, NULL, NULL, @v_adr_idtraduction out
						FETCH NEXT FROM c_adresse INTO @v_bas_systeme, @v_bas_base, @v_adr_sousbase, @v_adr_idtraduction
					END
					CLOSE c_adresse
					DEALLOCATE c_adresse
					WHILE ((@v_tag_outil > 0) AND (@v_error = 0))
					BEGIN
						IF NOT EXISTS (SELECT 1 FROM OUTIL_AGV WHERE OUA_IDAGV = @v_iag_id AND OUA_COLONNE = @v_tag_outil)
							INSERT INTO OUTIL_AGV (OUA_IDAGV, OUA_COLONNE) VALUES (@v_iag_id, @v_tag_outil)
						SET @v_error = @@ERROR
						SET @v_p = @v_tag_profondeur
						WHILE ((@v_p > 0) AND (@v_error = 0))
						BEGIN
							SET @v_n = @v_tag_niveau
							WHILE ((@v_n > 0) AND (@v_error = 0))
							BEGIN
								SET @v_c = @v_tag_colonne * @v_tag_outil
								WHILE ((@v_c > 0) AND (@v_error = 0))
								BEGIN
									SET @v_adr_sousbase = dbo.INT_GETIDSOUSBASE(@v_p, @v_n, @v_c)
									IF NOT EXISTS (SELECT 1 FROM ADRESSE WHERE ADR_SYSTEME = @v_bas_systeme AND ADR_BASE = @v_bas_base
										AND ADR_SOUSBASE = @v_adr_sousbase)
									BEGIN
										SET @v_lib_libelle = @v_iag_libelle + '-' + CONVERT(varchar, @v_p) + '.' + CONVERT(varchar, @v_n) + '.' + CONVERT(varchar, @v_c)
										EXEC @v_error = LIB_TRADUCTION 0, @v_lan_id, @v_lib_libelle, @v_adr_idtraduction out
										IF @v_error = 0
										BEGIN
											INSERT INTO ADRESSE (ADR_SYSTEME, ADR_BASE, ADR_SOUSBASE, ADR_PROFONDEUR, ADR_NIVEAU,
												ADR_COLONNE, ADR_TYPE, ADR_IDTRADUCTION) VALUES (@v_bas_systeme, @v_bas_base, @v_adr_sousbase,
												@v_p, @v_n, @v_c, 1, @v_adr_idtraduction)
											SET @v_error = @@ERROR
										END
									END
									SET @v_c = @v_c - 1
								END
								SET @v_n = @v_n - 1
							END
							SET @v_p = @v_p - 1
						END
						SET @v_tag_outil = @v_tag_outil - 1
					END
				END
				IF @v_error = 0
					SET @v_retour = 0
			END
			ELSE
				SET @v_retour = 114
		END
	END
	ELSE IF @v_action = 2
	BEGIN
		IF NOT EXISTS ((SELECT 1 FROM CHARGE INNER JOIN ADRESSE ON ADR_SYSTEME = CHG_ADR_KEYSYS AND ADR_BASE = CHG_ADR_KEYBASE AND ADR_SOUSBASE = CHG_ADR_KEYSSBASE
			INNER JOIN BASE ON BAS_SYSTEME = ADR_SYSTEME AND BAS_BASE = ADR_BASE WHERE BAS_TYPE_MAGASIN = 1 AND BAS_MAGASIN = @v_iag_id)
			UNION (SELECT 1 FROM MISSION WHERE MIS_IDAGV =  @v_iag_id AND MIS_IDETAT NOT IN (5, 6)))
		BEGIN
			SELECT DISTINCT @v_bas_systeme = BAS_SYSTEME, @v_bas_base = BAS_BASE FROM BASE WHERE BAS_TYPE_MAGASIN = 1 AND BAS_MAGASIN = @v_iag_id
			DECLARE c_adresse CURSOR LOCAL FOR SELECT ADR_SOUSBASE, ADR_IDTRADUCTION
				FROM ADRESSE WHERE ADR_SYSTEME = @v_bas_systeme AND ADR_BASE = @v_bas_base
			OPEN c_adresse
			FETCH NEXT FROM c_adresse INTO @v_adr_sousbase, @v_adr_idtraduction
			WHILE ((@@FETCH_STATUS = 0) AND (@v_error = 0))
			BEGIN
				DELETE ADRESSE WHERE ADR_SYSTEME = @v_bas_systeme AND ADR_BASE = @v_bas_base AND ADR_SOUSBASE = @v_adr_sousbase
				SET @v_error = @@ERROR
				IF @v_error = 0
					EXEC @v_error = LIB_TRADUCTION @v_action, NULL, NULL, @v_adr_idtraduction out
				FETCH NEXT FROM c_adresse INTO @v_adr_sousbase, @v_adr_idtraduction
			END
			CLOSE c_adresse
			DEALLOCATE c_adresse
			IF @v_error = 0
			BEGIN
				UPDATE MODE_EXPLOITATION SET MOD_NBAGVMAX = MOD_NBAGVMAX - 1 WHERE MOD_IDMODE = 1
				SET @v_error = @@ERROR
				IF @v_error = 0
				BEGIN				
					DELETE INTERACTION WHERE INR_DE = @v_iag_id OR INR_VERS = @v_iag_id
					SET @v_error = @@ERROR
					IF @v_error = 0
					BEGIN
						UPDATE INFO_AGV SET IAG_GENANT = NULL WHERE IAG_GENANT = @v_iag_id
						SET @v_error = @@ERROR
						IF @v_error = 0
						BEGIN
							DELETE EVT_ENERGIE_EN_COURS WHERE EEC_IDEVT IN (SELECT EVC_ID FROM CONFIG_EVT_ENERGIE WHERE EVC_AGV = @v_iag_id)
							SET @v_error = @@ERROR
							IF @v_error = 0
							BEGIN
								DELETE CONFIG_RSV_ENERGIE WHERE CRE_IDAGV = @v_iag_id
								SET @v_error = @@ERROR
								IF @v_error = 0
								BEGIN
									DELETE CONFIG_EVT_ENERGIE WHERE EVC_AGV = @v_iag_id
									SET @v_error = @@ERROR
									IF @v_error = 0
									BEGIN
										DELETE BATTERIE WHERE BAT_ID IN (2 * @v_iag_id - 1, 2 * @v_iag_id)
										SET @v_error = @@ERROR
										IF @v_error = 0
										BEGIN
											DELETE BASE WHERE BAS_SYSTEME = @v_bas_systeme AND BAS_BASE = @v_bas_base
											SET @v_error = @@ERROR
											IF @v_error = 0
											BEGIN
												DELETE OUTIL_AGV WHERE OUA_IDAGV = @v_iag_id
												SET @v_error = @@ERROR
												IF @v_error = 0
												BEGIN
													DELETE OCCUPATION_ZONE WHERE OZO_IDAGV = @v_iag_id
													SET @v_error = @@ERROR
													IF @v_error = 0
													BEGIN
														DELETE PLANIFICATION WHERE PLA_INFO_AGV = @v_iag_id
														SET @v_error = @@ERROR
														IF @v_error = 0
														BEGIN
															DELETE INFO_AGV WHERE IAG_ID = @v_iag_id
															SET @v_error = @@ERROR
															IF @v_error = 0
															BEGIN
																EXEC @v_error = LIB_TRADUCTION @v_action, NULL, NULL, @v_tra_id out
																IF @v_error = 0
																	SET @v_retour = 0
															END
														END
													END
												END
											END
										END
									END
								END
							END
						END
					END
				END
			END
		END
		ELSE
			SET @v_retour = 114
	END
	IF @v_local = 1
	BEGIN
		IF @v_error <> 0
			ROLLBACK TRAN AGV
		ELSE
			COMMIT TRAN AGV
	END
	RETURN @v_error

