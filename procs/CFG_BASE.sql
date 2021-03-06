SET ANSI_NULLS OFF
SET QUOTED_IDENTIFIER OFF



-----------------------------------------------------------------------------------------
-- Procédure		: CFG_BASE
-- Paramètre d'entrées	: @v_action : Action à mener
--			  @v_ssaction : Sous action à mener
--			  @v_bas_libelle_visible : Visibilité libellé
--			  @v_bas_pos_libelle_x : Position x libellé
--			  @v_bas_pos_libelle_y : Position y libellé
--			  @v_bas_pos_libelle_theta : Position theta libellé
--			  @v_bas_legende : Légende
--			  @v_bas_menu_contextuel : Menu contextuel
--			  @v_bas_vue : Vue
--			  @v_tmg_id : Type magasin
--			  @v_bas_visible : Visibilité
--			  @v_bas_charge_visible : Visibilité charge
--			  @v_bas_symbole : Symbole
--			  @v_bas_magasin : Magasin
--			  @v_bas_allee : Allee
--			  @v_bas_couloir : Couloir
--			  @v_bas_cote : Côté
--			  @v_bas_rack : Rack
--			  @v_profondeur : Profondeur
--			  @v_niveau : Niveau
--			  @v_colonne : Colonne
--			  @v_lan_id : Identifiant langue
--			  @v_lib_libelle : Libellé
--			  @v_bas_rayonnage : Rayonnage
--			  @v_bas_gerbage : Gerbage
--			  @v_bas_accumulation : Accumulation
--			  @v_bas_emplacement : Emplacement
--			  @v_coe_type : Type énergie
--			  @v_coe_rack : Rack
--			  @v_bas_biberonage : Biberonage
--			  @v_coe_accumulation : Accumulation maximale
-- Paramètre de sorties	: @v_retour : Code de retour
--			  @v_bas_systeme : Système
--			  @v_bas_base : Base
--			  @v_tra_id : Identifiant traduction
-- Descriptif		: Gestion des bases
-----------------------------------------------------------------------------------------

CREATE PROCEDURE [dbo].[CFG_BASE]
	@v_action smallint,
	@v_ssaction smallint,
	@v_bas_systeme bigint out,
	@v_bas_base bigint out,
	@v_bas_libelle_visible bit,
	@v_bas_pos_libelle_x int,
	@v_bas_pos_libelle_y int,
	@v_bas_pos_libelle_theta int,
	@v_bas_legende int,
	@v_bas_menu_contextuel int,
	@v_bas_vue int,
	@v_tmg_id tinyint,
	@v_bas_visible bit,
	@v_bas_charge_visible bit,
	@v_bas_symbole varchar(32),
	@v_bas_magasin smallint,
	@v_bas_allee tinyint,
	@v_bas_couloir smallint,
	@v_bas_cote tinyint,
	@v_bas_rack tinyint,
	@v_profondeur tinyint,
	@v_niveau tinyint,
	@v_colonne tinyint,
	@v_lan_id varchar(3),
	@v_tra_id int out,
	@v_lib_libelle varchar(8000),
	@v_bas_rayonnage bit,
	@v_bas_gerbage bit,
	@v_bas_accumulation bit,
	@v_bas_emplacement bit,
	@v_coe_type tinyint,
	@v_coe_rack tinyint,
	@v_bas_biberonage bit,
	@v_coe_accumulation	tinyint,
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
	@v_status int,
	@v_adr_systeme bigint,
	@v_adr_base bigint,
	@v_adr_sousbase bigint,
	@v_sys_client tinyint,
	@v_sys_site tinyint,
	@v_sys_secteur tinyint,
	@v_adr_idtraduction int,
	@v_adr_libelle varchar(8000),
	@v_p tinyint,
	@v_n tinyint,
	@v_c tinyint,
	@v_bas_type bit,
	@v_iag_id tinyint

	BEGIN TRAN
	SET @v_retour = 113
	SET @v_status = 0
	SET @v_error = 0
	IF @v_action = 0
	BEGIN
		IF EXISTS (SELECT 1 FROM SYSTEME)
		BEGIN
			SELECT TOP 1 @v_bas_systeme = SYS_SYSTEME FROM SYSTEME
			IF @v_ssaction = 1
				SET @v_bas_base = dbo.INT_GETIDBASE(@v_tmg_id, @v_bas_magasin, @v_bas_allee, @v_bas_couloir, @v_bas_cote, @v_bas_rack)
			IF NOT EXISTS (SELECT 1 FROM BASE, LIBELLE WHERE LIB_TRADUCTION = BAS_IDTRADUCTION AND LIB_LIBELLE = @v_lib_libelle)
				AND NOT EXISTS (SELECT 1 FROM BASE WHERE BAS_SYSTEME = @v_bas_systeme AND BAS_BASE = @v_bas_base)
			BEGIN
				EXEC @v_error = LIB_TRADUCTION @v_action, @v_lan_id, @v_lib_libelle, @v_tra_id out
				IF @v_error = 0
				BEGIN
					SET @v_sys_client = CONVERT(varchar, ROUND(@v_bas_systeme / POWER(CONVERT(bigint, 2), 16), 0))
					SET @v_sys_site = CONVERT(varchar, ROUND((@v_bas_systeme - @v_sys_client * POWER(CONVERT(bigint, 2), 16)) / POWER(CONVERT(bigint, 2), 8), 0))
					SET @v_sys_secteur = CONVERT(varchar, @v_bas_systeme - @v_sys_site * POWER(CONVERT(bigint, 2), 8) - @v_sys_client * POWER(CONVERT(bigint, 2), 16))
					IF @v_ssaction = 0
					BEGIN
						SET @v_bas_magasin = CONVERT(varchar, ROUND((@v_bas_base - @v_tmg_id * POWER(CONVERT(bigint, 2), 56)) / POWER(CONVERT(bigint, 2), 40), 0))
						SET @v_bas_allee = CONVERT(varchar, ROUND((@v_bas_base - @v_bas_magasin * POWER(CONVERT(bigint, 2), 40) - @v_tmg_id * POWER(CONVERT(bigint, 2), 56)) / POWER(CONVERT(bigint, 2), 32), 0))
						SET @v_bas_couloir = CONVERT(varchar, ROUND((@v_bas_base - @v_bas_allee * POWER(CONVERT(bigint, 2), 32) - @v_bas_magasin * POWER(CONVERT(bigint, 2), 40) - @v_tmg_id * POWER(CONVERT(bigint, 2), 56)) / POWER(CONVERT(bigint, 2), 16), 0))
						SET @v_bas_cote = CONVERT(varchar, ROUND((@v_bas_base - @v_bas_couloir * POWER(CONVERT(bigint, 2), 16) - @v_bas_allee * POWER(CONVERT(bigint, 2), 32) - @v_bas_magasin * POWER(CONVERT(bigint, 2), 40) - @v_tmg_id * POWER(CONVERT(bigint, 2), 56)) / POWER(CONVERT(bigint, 2), 8), 0))
						SET @v_bas_rack = CONVERT(varchar, @v_bas_base - @v_bas_cote * POWER(CONVERT(bigint, 2), 8) - @v_bas_couloir * POWER(CONVERT(bigint, 2), 16) - @v_bas_allee * POWER(CONVERT(bigint, 2), 32) - @v_bas_magasin * POWER(CONVERT(bigint, 2), 40) - @v_tmg_id * POWER(CONVERT(bigint, 2), 56))
					END
					SET @v_bas_type = CASE WHEN @v_bas_magasin = 0 OR @v_bas_allee = 0 OR @v_bas_couloir = 0 OR @v_bas_cote = 0 OR @v_bas_rack = 0 THEN 0 ELSE 1 END
					SET @v_bas_legende = CASE @v_tmg_id WHEN 2 THEN 2 WHEN 3 THEN 4 WHEN 4 THEN 8 WHEN 5 THEN 3 WHEN 6 THEN CASE @v_coe_type WHEN 1 THEN 11 WHEN 2 THEN 10 WHEN 3 THEN 9 WHEN 4 THEN 12 ELSE NULL END ELSE NULL END
					SET @v_bas_menu_contextuel = CASE @v_tmg_id WHEN 6 THEN CASE @v_coe_type WHEN 1 THEN 6 WHEN 2 THEN 5 WHEN 3 THEN 2 WHEN 4 THEN 7 ELSE NULL END ELSE NULL END
					INSERT INTO BASE (BAS_SYSTEME, BAS_BASE, BAS_IDTRADUCTION, BAS_LIBELLE_VISIBLE, BAS_TYPE_MAGASIN, BAS_MAGASIN,
						BAS_ALLEE, BAS_COULOIR, BAS_COTE, BAS_RACK, BAS_TYPE, BAS_POS_LIBELLE_X, BAS_POS_LIBELLE_Y, BAS_POS_LIBELLE_THETA,
						BAS_LEGENDE, BAS_MENU_CONTEXTUEL, BAS_VISIBLE, BAS_SYMBOLE, BAS_RAYONNAGE, BAS_GERBAGE, BAS_ACCUMULATION, BAS_EMPLACEMENT)
						VALUES (@v_bas_systeme, @v_bas_base, @v_tra_id, @v_bas_libelle_visible, @v_tmg_id, @v_bas_magasin, @v_bas_allee,
						@v_bas_couloir, @v_bas_cote, @v_bas_rack, @v_bas_type, @v_bas_pos_libelle_x, @v_bas_pos_libelle_y, @v_bas_pos_libelle_theta,
						@v_bas_legende, @v_bas_menu_contextuel, @v_bas_visible, @v_bas_symbole, @v_bas_rayonnage, @v_bas_gerbage, @v_bas_accumulation, @v_bas_emplacement)
					SET @v_error = @@ERROR
					IF @v_error = 0
					BEGIN
						IF @v_bas_type = 1
						BEGIN
							EXEC @v_status = CFG_SOUSBASE @v_bas_systeme, @v_bas_base, @v_lib_libelle, @v_profondeur, @v_niveau, @v_colonne, @v_lan_id, @v_retour out
							SET @v_error = @@ERROR
							IF ((@v_status = 0) AND (@v_error = 0))
							BEGIN
								IF @v_tmg_id = 6 OR @v_bas_biberonage = 1
								BEGIN
									SET @v_adr_sousbase = dbo.INT_GETIDSOUSBASE(1, 1, 1)
									IF @v_coe_type IS NULL AND @v_bas_biberonage = 1
										SET @v_coe_type = 4
									INSERT INTO CONFIG_OBJ_ENERGIE (COE_ID, COE_TYPE, COE_MAXACCU, COE_ENSERVICE, COE_ADRSYS, COE_ADRBASE, COE_ADRSSBASE, COE_RACK)
										SELECT ISNULL((SELECT MAX(COE_ID) + 1 FROM CONFIG_OBJ_ENERGIE), 1), @v_coe_type, 1, 1, @v_bas_systeme, @v_bas_base, @v_adr_sousbase, @v_coe_rack
									SET @v_error = @@ERROR
									IF @v_error = 0
									BEGIN
										UPDATE TYPE_EVT_ENERGIE SET TAE_AUTORISE = CASE WHEN EXISTS (SELECT 1 FROM CONFIG_OBJ_ENERGIE WHERE ((COE_TYPE IN (1, 2, 3) AND TAE_ID = 1) OR (COE_TYPE = 4 AND TAE_ID IN (2, 3, 4)))) THEN 1 ELSE 0 END
										SET @v_error = @@ERROR
										IF @v_error = 0
											SET @v_retour = 0
									END
								END
								ELSE
									SET @v_retour = 0
							END
						END
						ELSE
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
	ELSE IF @v_action = 1
	BEGIN
		IF @v_ssaction = 0
		BEGIN
			IF NOT EXISTS (SELECT 1 FROM BASE, LIBELLE WHERE LIB_TRADUCTION = BAS_IDTRADUCTION AND LIB_LIBELLE = @v_lib_libelle)
			BEGIN
				UPDATE LIBELLE SET LIB_LIBELLE = @v_lib_libelle WHERE LIB_LANGUE = @v_lan_id AND LIB_TRADUCTION = @v_tra_id
				SET @v_error = @@ERROR
				IF @v_error = 0
				BEGIN
					DECLARE c_adresse CURSOR LOCAL FOR SELECT ADR_IDTRADUCTION, ADR_PROFONDEUR, ADR_NIVEAU, ADR_COLONNE FROM ADRESSE
						WHERE ADR_SYSTEME = @v_bas_systeme AND ADR_BASE = @v_bas_base
					OPEN c_adresse
					FETCH NEXT FROM c_adresse INTO @v_adr_idtraduction, @v_p, @v_n, @v_c
					WHILE ((@@FETCH_STATUS = 0) AND (@v_error = 0))
					BEGIN
						UPDATE LIBELLE SET LIB_LIBELLE = @v_lib_libelle + '-' + CONVERT(varchar, @v_p) + '.' + CONVERT(varchar, @v_n) + '.' + CONVERT(varchar, @v_c)
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
			UPDATE BASE SET BAS_LIBELLE_VISIBLE = @v_bas_libelle_visible, BAS_POS_LIBELLE_X = @v_bas_pos_libelle_x, BAS_POS_LIBELLE_Y = @v_bas_pos_libelle_y, BAS_POS_LIBELLE_THETA = @v_bas_pos_libelle_theta
				WHERE BAS_SYSTEME = @v_bas_systeme AND BAS_BASE = @v_bas_base
			SET @v_error = @@ERROR
			IF @v_error = 0
				SET @v_retour = 0
		END
		ELSE IF @v_ssaction = 2
		BEGIN
			UPDATE BASE SET BAS_POS_LIBELLE_X = @v_bas_pos_libelle_x, BAS_POS_LIBELLE_Y = @v_bas_pos_libelle_y, BAS_POS_LIBELLE_THETA = @v_bas_pos_libelle_theta
				WHERE BAS_SYSTEME = @v_bas_systeme AND BAS_BASE = @v_bas_base
			SET @v_error = @@ERROR
			IF @v_error = 0
				SET @v_retour = 0
		END
		ELSE IF @v_ssaction = 3
		BEGIN
			UPDATE BASE SET BAS_VISIBLE = @v_bas_visible, BAS_CHARGE_VISIBLE = CASE @v_bas_visible WHEN 0 THEN 0 ELSE BAS_CHARGE_VISIBLE END,
				BAS_SYMBOLE = @v_bas_symbole WHERE BAS_SYSTEME = @v_bas_systeme AND BAS_BASE = @v_bas_base
			SET @v_error = @@ERROR
			IF @v_error = 0
				SET @v_retour = 0
		END
		ELSE IF @v_ssaction = 4
		BEGIN
			UPDATE BASE SET BAS_LEGENDE = @v_bas_legende WHERE BAS_SYSTEME = @v_bas_systeme AND BAS_BASE = @v_bas_base
			SET @v_error = @@ERROR
			IF @v_error = 0
				SET @v_retour = 0
		END
		ELSE IF @v_ssaction = 5
		BEGIN
			UPDATE BASE SET BAS_MENU_CONTEXTUEL = @v_bas_menu_contextuel WHERE BAS_SYSTEME = @v_bas_systeme AND BAS_BASE = @v_bas_base
			SET @v_error = @@ERROR
			IF @v_error = 0
				SET @v_retour = 0
		END
		ELSE IF @v_ssaction = 6
		BEGIN
			UPDATE BASE SET BAS_VUE = @v_bas_vue WHERE BAS_SYSTEME = @v_bas_systeme AND BAS_BASE = @v_bas_base
			SET @v_error = @@ERROR
			IF @v_error = 0
				SET @v_retour = 0
		END
		ELSE IF @v_ssaction = 7
		BEGIN
			UPDATE BASE SET BAS_SYMBOLE = @v_bas_symbole, BAS_RAYONNAGE = @v_bas_rayonnage, BAS_GERBAGE = @v_bas_gerbage,
				BAS_ACCUMULATION = @v_bas_accumulation, BAS_EMPLACEMENT = @v_bas_emplacement WHERE BAS_SYSTEME = @v_bas_systeme AND BAS_BASE = @v_bas_base
			SET @v_error = @@ERROR
			IF @v_error = 0 AND @v_bas_emplacement = 0
			BEGIN
				UPDATE ADRESSE SET ADR_EMPLACEMENT_VIDE = NULL, ADR_EMPLACEMENT_OCCUPE = NULL, ADR_ETAT_OCCUPATION = NULL
					WHERE ADR_SYSTEME = @v_bas_systeme AND ADR_BASE = @v_bas_base
				SET @v_error = @@ERROR
			END
			IF @v_error = 0
			BEGIN
				SET @v_adr_sousbase = dbo.INT_GETIDSOUSBASE(1, 1, 1)
				IF @v_tmg_id = 6 OR @v_bas_biberonage = 1
				BEGIN
					IF @v_coe_type IS NULL AND @v_bas_biberonage = 1
						SET @v_coe_type = 4
					IF NOT EXISTS (SELECT 1 FROM CONFIG_OBJ_ENERGIE WHERE COE_ADRSYS = @v_bas_systeme AND COE_ADRBASE = @v_bas_base AND COE_ADRSSBASE = @v_adr_sousbase)
					BEGIN
						INSERT INTO CONFIG_OBJ_ENERGIE (COE_ID, COE_TYPE, COE_MAXACCU, COE_ENSERVICE, COE_ADRSYS, COE_ADRBASE, COE_ADRSSBASE, COE_RACK)
							SELECT ISNULL((SELECT MAX(COE_ID) + 1 FROM CONFIG_OBJ_ENERGIE), 1), @v_coe_type, 1, 1, @v_bas_systeme, @v_bas_base, @v_adr_sousbase, @v_coe_rack
						SET @v_error = @@ERROR
						IF @v_error = 0
						BEGIN
							UPDATE TYPE_EVT_ENERGIE SET TAE_AUTORISE = CASE WHEN EXISTS (SELECT 1 FROM CONFIG_OBJ_ENERGIE WHERE ((COE_TYPE IN (1, 2, 3) AND TAE_ID = 1) OR (COE_TYPE = 4 AND TAE_ID IN (2, 3, 4)))) THEN 1 ELSE 0 END
							SET @v_error = @@ERROR
							IF @v_error = 0
								SET @v_retour = 0
						END
					END
					IF @v_error = 0
					BEGIN
						DELETE CONFIG_RSV_ENERGIE WHERE CRE_IDOBJ IN (SELECT COE_ID FROM CONFIG_OBJ_ENERGIE WHERE COE_RACK = @v_coe_rack) OR CRE_IDOBJ = (SELECT COE_ID FROM CONFIG_OBJ_ENERGIE WHERE COE_ADRSYS = @v_bas_systeme AND COE_ADRBASE = @v_bas_base AND COE_ADRSSBASE = @v_adr_sousbase)
						SET @v_error = @@ERROR
						IF @v_error = 0
						BEGIN
							DECLARE c_batterie CURSOR LOCAL FAST_FORWARD FOR SELECT CEILING(CONVERT(FLOAT, BAT_ID) / 2) FROM BATTERIE WHERE BAT_CONFIG_OBJ_ENERGIE IN (SELECT COE_ID FROM CONFIG_OBJ_ENERGIE WHERE COE_RACK = @v_coe_rack) OR BAT_CONFIG_OBJ_ENERGIE = (SELECT COE_ID FROM CONFIG_OBJ_ENERGIE WHERE COE_ADRSYS = @v_bas_systeme AND COE_ADRBASE = @v_bas_base AND COE_ADRSSBASE = @v_adr_sousbase)
							OPEN c_batterie
							FETCH NEXT FROM c_batterie INTO @v_iag_id
							WHILE ((@@FETCH_STATUS = 0) AND (@v_error = 0))
							BEGIN
								DELETE BATTERIE WHERE BAT_ID IN (2 * @v_iag_id - 1, 2 * @v_iag_id)
								SET @v_error = @@ERROR
								FETCH NEXT FROM c_batterie INTO @v_iag_id
							END
							CLOSE c_batterie
							DEALLOCATE c_batterie
							IF @v_error = 0
							BEGIN
								UPDATE CONFIG_OBJ_ENERGIE SET COE_TYPE = @v_coe_type, COE_RACK = @v_coe_rack WHERE COE_ADRSYS = @v_bas_systeme AND COE_ADRBASE = @v_bas_base AND COE_ADRSSBASE = @v_adr_sousbase
								SET @v_error = @@ERROR
								IF @v_error = 0
								BEGIN
									UPDATE TYPE_EVT_ENERGIE SET TAE_AUTORISE = CASE WHEN EXISTS (SELECT 1 FROM CONFIG_OBJ_ENERGIE WHERE ((COE_TYPE IN (1, 2, 3) AND TAE_ID = 1) OR (COE_TYPE = 4 AND TAE_ID IN (2, 3, 4)))) THEN 1 ELSE 0 END
									SET @v_error = @@ERROR
									IF @v_error = 0
										SET @v_retour = 0
								END
							END
						END
					END
				END
				ELSE IF @v_bas_biberonage = 0
				BEGIN
					DELETE CONFIG_RSV_ENERGIE WHERE CRE_IDOBJ IN (SELECT COE_ID FROM CONFIG_OBJ_ENERGIE WHERE COE_ADRSYS = @v_bas_systeme AND COE_ADRBASE = @v_bas_base AND COE_ADRSSBASE = @v_adr_sousbase)
					SET @v_error = @@ERROR
					IF @v_error = 0
					BEGIN
						DELETE BATTERIE WHERE BAT_CONFIG_OBJ_ENERGIE IN (SELECT COE_ID FROM CONFIG_OBJ_ENERGIE WHERE COE_ADRSYS = @v_bas_systeme AND COE_ADRBASE = @v_bas_base AND COE_ADRSSBASE = @v_adr_sousbase)
						SET @v_error = @@ERROR
						IF @v_error = 0
						BEGIN
							DELETE CONFIG_OBJ_ENERGIE WHERE COE_ADRSYS = @v_bas_systeme AND COE_ADRBASE = @v_bas_base AND COE_ADRSSBASE = @v_adr_sousbase
							SET @v_error = @@ERROR
							IF @v_error = 0
							BEGIN
								UPDATE TYPE_EVT_ENERGIE SET TAE_AUTORISE = CASE WHEN EXISTS (SELECT 1 FROM CONFIG_OBJ_ENERGIE WHERE ((COE_TYPE IN (1, 2, 3) AND TAE_ID = 1) OR (COE_TYPE = 4 AND TAE_ID IN (2, 3, 4)))) THEN 1 ELSE 0 END
								SET @v_error = @@ERROR
								IF @v_error = 0
									SET @v_retour = 0
							END
						END
					END
				END
			END
				SET @v_retour = 0
		END
		ELSE IF @v_ssaction = 8
		BEGIN
			SET @v_adr_sousbase = dbo.INT_GETIDSOUSBASE(1, 1, 1)
			UPDATE CONFIG_OBJ_ENERGIE SET COE_MAXACCU = @v_coe_accumulation WHERE COE_ADRSYS = @v_bas_systeme AND COE_ADRBASE = @v_bas_base AND COE_ADRSSBASE = @v_adr_sousbase
			SET @v_error = @@ERROR
			IF @v_error = 0
				SET @v_retour = 0
		END
		ELSE IF @v_ssaction = 9
		BEGIN
			UPDATE BASE SET BAS_CHARGE_VISIBLE = @v_bas_charge_visible WHERE BAS_SYSTEME = @v_bas_systeme AND BAS_BASE = @v_bas_base
			SET @v_error = @@ERROR
			IF @v_error = 0
				SET @v_retour = 0
		END
	END
	ELSE IF @v_action = 2
	BEGIN
		IF NOT EXISTS ((SELECT 1 FROM CHARGE, ADRESSE WHERE CHG_ADR_KEYSYS = ADR_SYSTEME AND CHG_ADR_KEYBASE = ADR_BASE
					AND CHG_ADR_KEYSSBASE = ADR_SOUSBASE AND ADR_SYSTEME = @v_bas_systeme AND ADR_BASE = @v_bas_base)
			UNION (SELECT 1 FROM TACHE, ADRESSE WHERE TAC_IDADRSYS = ADR_SYSTEME AND TAC_IDADRBASE = ADR_BASE
					AND TAC_IDADRSSBASE = ADR_SOUSBASE AND ADR_SYSTEME = @v_bas_systeme AND ADR_BASE = @v_bas_base)
			UNION (SELECT 1 FROM EVT_ENERGIE_EN_COURS WHERE EEC_IDOBJ IN (SELECT COE_ID FROM CONFIG_OBJ_ENERGIE WHERE COE_ADRSYS = @v_bas_systeme AND COE_ADRBASE = @v_bas_base))
			UNION (SELECT 1 FROM CONTEXTE WHERE COT_BASE_SYS = @v_bas_systeme AND COT_BASE_BASE = @v_bas_base)
			UNION (SELECT 1 FROM CONDITION WHERE CDT_VALEUR = @v_bas_base AND CDT_IDTRADUCTIONTEXTE = @v_tra_id)
			UNION (SELECT 1 FROM ACTION_REGLE WHERE ARE_PARAMS = @v_bas_base AND ARE_IDTRADUCTIONTEXTE = @v_tra_id)
			UNION (SELECT 1 FROM VARIABLE WHERE VAR_PARAMETRE = @v_bas_base AND VAR_TRADUCTIONTEXTE = @v_tra_id))
		BEGIN
			DELETE ZONE_CONTENU WHERE CZO_ADR_KEY_SYS = @v_bas_systeme AND CZO_ADR_KEY_BASE = @v_bas_base
			SET @v_error = @@ERROR
			IF @v_error = 0
			BEGIN
				DELETE ASSOCIATION_BASE_REGION WHERE ABR_SYSTEME = @v_bas_systeme AND ABR_BASE = @v_bas_base
				SET @v_error = @@ERROR
				IF @v_error = 0
				BEGIN
					DELETE FLUX WHERE (FLU_PRS_ADRSYS = @v_bas_systeme AND FLU_PRS_ADRBASE = @v_bas_base)
						OR (FLU_DEP_ADRSYS = @v_bas_systeme AND FLU_DEP_ADRBASE = @v_bas_base)
					SET @v_error = @@ERROR
					IF @v_error = 0
					BEGIN
						DECLARE c_adresse CURSOR LOCAL FOR SELECT ADR_SYSTEME, ADR_BASE, ADR_SOUSBASE, ADR_IDTRADUCTION FROM ADRESSE
							WHERE ADR_SYSTEME = @v_bas_systeme AND ADR_BASE = @v_bas_base FOR UPDATE
						OPEN c_adresse
						FETCH NEXT FROM c_adresse INTO @v_adr_systeme, @v_adr_base, @v_adr_sousbase, @v_adr_idtraduction
						WHILE ((@@FETCH_STATUS = 0) AND (@v_error = 0))
						BEGIN
							DELETE CONFIG_RSV_ENERGIE WHERE CRE_IDOBJ IN (SELECT COE_ID FROM CONFIG_OBJ_ENERGIE WHERE COE_ADRSYS = @v_adr_systeme AND COE_ADRBASE = @v_adr_base AND COE_ADRSSBASE = @v_adr_sousbase)
							SET @v_error = @@ERROR
							IF @v_error = 0
							BEGIN
								DELETE BATTERIE WHERE BAT_CONFIG_OBJ_ENERGIE IN (SELECT COE_ID FROM CONFIG_OBJ_ENERGIE WHERE COE_ADRSYS = @v_adr_systeme AND COE_ADRBASE = @v_adr_base AND COE_ADRSSBASE = @v_adr_sousbase)
								SET @v_error = @@ERROR
								IF @v_error = 0
								BEGIN
									DELETE CONFIG_OBJ_ENERGIE WHERE COE_ADRSYS = @v_adr_systeme AND COE_ADRBASE = @v_adr_base AND COE_ADRSSBASE = @v_adr_sousbase
									SET @v_error = @@ERROR
									IF @v_error = 0
									BEGIN
										UPDATE TYPE_EVT_ENERGIE SET TAE_AUTORISE = CASE WHEN EXISTS (SELECT 1 FROM CONFIG_OBJ_ENERGIE WHERE ((COE_TYPE IN (1, 2, 3) AND TAE_ID = 1) OR (COE_TYPE = 4 AND TAE_ID IN (2, 3, 4)))) THEN 1 ELSE 0 END
										SET @v_error = @@ERROR
										IF @v_error = 0
										BEGIN
											DELETE STRUCTURE WHERE STR_SYSTEME = @v_adr_systeme AND STR_BASE = @v_adr_base AND STR_SOUSBASE = @v_adr_sousbase
											SET @v_error = @@ERROR
											IF @v_error = 0
											BEGIN
												DELETE ADRESSE WHERE CURRENT OF c_adresse
												SET @v_error = @@ERROR
												IF @v_error = 0
													EXEC @v_error = LIB_TRADUCTION @v_action, NULL, NULL, @v_adr_idtraduction out
											END
										END
									END
								END
							END
							FETCH NEXT FROM c_adresse INTO @v_adr_systeme, @v_adr_base, @v_adr_sousbase, @v_adr_idtraduction
						END
						CLOSE c_adresse
						DEALLOCATE c_adresse
						IF @v_error = 0
						BEGIN
							DELETE BASE WHERE BAS_SYSTEME = @v_bas_systeme AND BAS_BASE = @v_bas_base
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
		ELSE
			SET @v_retour = 114
	END
	IF ((@v_error = 0) AND (@v_retour = 0))
		COMMIT TRAN
	ELSE
		ROLLBACK TRAN
	RETURN @v_error

