SET ANSI_NULLS OFF
SET QUOTED_IDENTIFIER OFF



-----------------------------------------------------------------------------------------
-- Procédure		: CFG_TYPEAGV
-- Paramètre d'entrées	: @v_action : Action  à mener
--			  @v_ssaction : Sous action à mener
--			  @v_tag_id : Identifiant type AGV
--			  @v_tag_outil : Outil
--			  @v_tag_profondeur : Profondeur
--			  @v_tag_niveau : Niveau
--			  @v_tag_colonne : Colonne
--			  @v_tag_symbole : Symbole
--			  @v_tag_legende : Légende
--			  @v_tag_menu_contextuel : Menu contextuel
--			  @v_tag_vue : Vue
--			  @v_tag_fourche : Fourche
--			  @v_tag_type_outil : Identifiant type outil
--			  @v_lib_libelle : Libellé
--			  @v_lan_id : Identifiant langue
-- Paramètre de sorties	: @v_retour : Code de retour
--			  @v_tra_id : Identifiant traduction
-- Descriptif		: Gestion des types d'AGVs
-----------------------------------------------------------------------------------------

CREATE PROCEDURE [dbo].[CFG_TYPEAGV]
	@v_action smallint,
	@v_ssaction smallint,
	@v_tag_id tinyint,
	@v_tag_outil tinyint,
	@v_tag_profondeur tinyint,
	@v_tag_niveau tinyint,
	@v_tag_colonne tinyint,
	@v_tag_symbole varchar(32),
	@v_tag_legende int,
	@v_tag_menu_contextuel int,
	@v_tag_vue int,
	@v_tag_fourche smallint,
	@v_tag_type_outil tinyint,
	@v_tra_id int out,
	@v_lib_libelle varchar(8000),
	@v_lan_id varchar(3),
	@v_retour smallint out
AS

IF 1 = 0
BEGIN
	-- This line will be executed if FMTONLY was initially set to ON
	SET FMTONLY OFF
	RETURN
END

-- Déclaration des variables
DECLARE
	@v_error smallint,
	@v_iag_id tinyint,
	@v_iag_idtraduction int,
	@v_ema_keysys bigint,
	@v_ema_keybase bigint,
	@v_ema_keyssbase bigint,
	@v_adr_idtraduction int,
	@v_bas_idtraduction int
	
-- Déclaration des constantes de menu contextuel
DECLARE
	@MENU_AGV int

-- Déclaration des constantes de légendes
DECLARE
	@LEGE_AGV smallint

-- Définition des constantes
	SET @v_retour = 113
	SET @v_error = 0
	SET @MENU_AGV = 3
	SET @LEGE_AGV = 1

	BEGIN TRAN
	IF @v_action = 0
	BEGIN
		IF NOT EXISTS (SELECT 1 FROM TYPE_AGV WHERE TAG_ID = @v_tag_id)
		BEGIN
			EXEC @v_error = LIB_TRADUCTION @v_action, @v_lan_id, @v_lib_libelle, @v_tra_id out
			IF @v_error = 0
			BEGIN
				INSERT INTO TYPE_AGV (TAG_ID, TAG_IDTRADUCTION, TAG_OUTIL, TAG_PROFONDEUR, TAG_NIVEAU, TAG_COLONNE, TAG_SYMBOLE,
					TAG_MENU_CONTEXTUEL, TAG_LEGENDE, TAG_FOURCHE, TAG_TYPE_OUTIL) VALUES (@v_tag_id, @v_tra_id, @v_tag_outil, @v_tag_profondeur, @v_tag_niveau,
					@v_tag_colonne, @v_tag_symbole, @MENU_AGV, @LEGE_AGV, @v_tag_fourche, @v_tag_type_outil)
				SET @v_error = @@ERROR
				IF @v_error = 0
					SET @v_retour = 0
			END
		END
		ELSE
			SET @v_retour = 117
	END
	ELSE IF @v_action = 1
	BEGIN
		IF @v_ssaction = 0
		BEGIN
			UPDATE TYPE_AGV SET TAG_SYMBOLE = @v_tag_symbole, TAG_LEGENDE = @v_tag_legende, TAG_MENU_CONTEXTUEL = @v_tag_menu_contextuel,
				TAG_VUE = @v_tag_vue WHERE TAG_ID = @v_tag_id
			SET @v_error = @@ERROR
			IF @v_error = 0
				SET @v_retour = 0
		END
		ELSE IF @v_ssaction = 1
		BEGIN
			UPDATE TYPE_AGV SET TAG_FOURCHE = @v_tag_fourche, TAG_OUTIL = @v_tag_outil,
				TAG_PROFONDEUR = @v_tag_profondeur, TAG_NIVEAU = @v_tag_niveau, TAG_COLONNE = @v_tag_colonne WHERE TAG_ID = @v_tag_id
			SET @v_error = @@ERROR
			IF @v_error = 0
			BEGIN
				DECLARE c_agv CURSOR LOCAL FOR SELECT IAG_ID, LIB_LIBELLE FROM INFO_AGV, LIBELLE WHERE IAG_TYPE = @v_tag_id AND LIB_TRADUCTION = IAG_IDTRADUCTION AND LIB_LANGUE = @v_lan_id
				OPEN c_agv
				FETCH NEXT FROM c_agv INTO @v_iag_id, @v_lib_libelle
				WHILE ((@@FETCH_STATUS = 0) AND (@v_error = 0))
				BEGIN
					EXEC @v_error = CFG_AGV @v_action, 1, @v_iag_id, @v_tag_id, NULL, @v_lib_libelle, @v_lan_id, @v_retour out
					IF @v_retour <> 0
						BREAK
					FETCH NEXT FROM c_agv INTO @v_iag_id, @v_lib_libelle
				END
				CLOSE c_agv
				DEALLOCATE c_agv
			END
		END
	END
	ELSE IF @v_action = 2
	BEGIN
		IF NOT EXISTS ((SELECT 1 FROM CHARGE INNER JOIN ADRESSE ON ADR_SYSTEME = CHG_ADR_KEYSYS AND ADR_BASE = CHG_ADR_KEYBASE AND ADR_SOUSBASE = CHG_ADR_KEYSSBASE
			INNER JOIN BASE ON BAS_SYSTEME = ADR_SYSTEME AND BAS_BASE = ADR_BASE INNER JOIN INFO_AGV ON BAS_MAGASIN = IAG_ID
			WHERE BAS_TYPE_MAGASIN = 1 AND IAG_TYPE = @v_tag_id)
			UNION (SELECT 1 FROM MISSION, INFO_AGV WHERE IAG_ID = MIS_IDAGV AND IAG_TYPE =  @v_tag_id))
		BEGIN
			IF NOT EXISTS (SELECT 1 FROM INFO_AGV WHERE IAG_TYPE = @v_tag_id)
				SET @v_retour = 0
			ELSE
			BEGIN
				DECLARE c_agv CURSOR LOCAL FOR SELECT IAG_ID, IAG_IDTRADUCTION FROM INFO_AGV
					WHERE IAG_TYPE = @v_tag_id
				OPEN c_agv
				FETCH NEXT FROM c_agv INTO @v_iag_id, @v_iag_idtraduction
				WHILE ((@@FETCH_STATUS = 0) AND (@v_error = 0))
				BEGIN
					EXEC @v_error = CFG_AGV @v_action, NULL, @v_iag_id, @v_tag_id, @v_iag_idtraduction, NULL, NULL, @v_retour out
					IF @v_retour <> 0
						BREAK
					FETCH NEXT FROM c_agv INTO @v_iag_id, @v_iag_idtraduction
				END
				CLOSE c_agv
				DEALLOCATE c_agv
			END
			IF ((@v_error = 0) AND (@v_retour = 0))
			BEGIN
				DELETE TYPE_AGV WHERE TAG_ID = @v_tag_id
				SET @v_error = @@ERROR
				IF @v_error = 0
				BEGIN
					EXEC @v_error = LIB_TRADUCTION @v_action, @v_lan_id, @v_lib_libelle, @v_tra_id out
					IF @v_error = 0
						SET @v_retour = 0
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

