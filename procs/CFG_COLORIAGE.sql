SET ANSI_NULLS OFF
SET QUOTED_IDENTIFIER ON




-----------------------------------------------------------------------------------------
-- Procédure		: CFG_COLORIAGE
-- Paramètre d'entrées	: @v_action : Action à mener
--			  @v_vue_id : Identifiant vue
--			  @v_lan_id : Identifiant langue
--			  @v_lib_libelle : Libellé
--			  @v_clr_ordre : Ordre
--			  @v_clr_couleur : Couleur
--			  @v_clr_sql : SQL
-- Paramètre de sorties	: @v_retour : Code de retour
--			  @v_clr_id : Identifiant
--			  @v_tra_id : Identifiant traduction
-- Descriptif		: Gestion des règles de coloriage
-----------------------------------------------------------------------------------------

CREATE PROCEDURE [dbo].[CFG_COLORIAGE]
	@v_action smallint,
	@v_vue_id int,
	@v_clr_id int out,
	@v_tra_id int out,
	@v_lan_id varchar(3),
	@v_lib_libelle varchar(8000),
	@v_clr_ordre tinyint,
	@v_clr_couleur int,
	@v_clr_sql varchar(7000),
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
	@v_sql varchar(8000),
	@v_charindexwhere int,
	@v_charindexgroupby int

DECLARE
	@v_cursor varchar(8000)

	IF @@TRANCOUNT > 0
		SELECT @v_local = 0
	ELSE
	BEGIN
		SELECT @v_local = 1
		BEGIN TRAN COLORIAGE
	END
	SELECT @v_retour = 113
	SELECT @v_error = 0
	IF @v_action = 0
	BEGIN
		SELECT @v_sql = TAB_SQL FROM TABLEAU WHERE TAB_VUE = @v_vue_id
		EXEC ('SELECT * FROM (' + @v_sql + ') #TMP WHERE ' + @v_clr_sql)
		SELECT @v_error = @@ERROR
		IF @v_error = 0
		BEGIN
			EXEC @v_error = LIB_TRADUCTION @v_action, @v_lan_id, @v_lib_libelle, @v_tra_id out
			IF @v_error = 0
			BEGIN
				INSERT INTO COLORIAGE (CLR_TRADUCTION, CLR_COULEUR, CLR_TABLEAU, CLR_SQL, CLR_ORDRE)
					VALUES (@v_tra_id, @v_clr_couleur, @v_vue_id, @v_clr_sql, @v_clr_ordre)
				SELECT @v_error = @@ERROR
				IF @v_error = 0
				BEGIN
					SELECT @v_clr_id = SCOPE_IDENTITY()
					UPDATE COLORIAGE SET CLR_ORDRE = CLR_ORDRE + 1 WHERE CLR_TABLEAU = @v_vue_id AND CLR_ID <> @v_clr_id AND CLR_ORDRE >= @v_clr_ordre
					SELECT @v_error = @@ERROR
					IF @v_error = 0
						SELECT @v_retour = 0
				END
			END
		END
	END
	ELSE IF @v_action = 1
	BEGIN
		SELECT @v_sql = TAB_SQL FROM TABLEAU WHERE TAB_VUE = @v_vue_id
		EXEC ('SELECT * FROM (' + @v_sql + ') #TMP WHERE ' + @v_clr_sql)
		SELECT @v_error = @@ERROR
		IF @v_error = 0
		BEGIN
			UPDATE LIBELLE SET LIB_LIBELLE = @v_lib_libelle WHERE LIB_TRADUCTION = @v_tra_id AND LIB_LANGUE = @v_lan_id
			SELECT @v_error = @@ERROR
			IF @v_error = 0
			BEGIN
				UPDATE COLORIAGE SET CLR_COULEUR = @v_clr_couleur, CLR_SQL = @v_clr_sql WHERE CLR_ID = @v_clr_id
				SELECT @v_error = @@ERROR
				IF @v_error = 0
					SELECT @v_retour = 0
			END
		END
	END
	ELSE IF @v_action = 2
	BEGIN
		DELETE ASSOCIATION_COLORIAGE_UTILISATEUR WHERE ALU_COLORIAGE = @v_clr_id
		SELECT @v_error = @@ERROR
		IF @v_error = 0
		BEGIN
			DELETE ASSOCIATION_COLORIAGE_GROUPE WHERE ALG_COLORIAGE = @v_clr_id
			SELECT @v_error = @@ERROR
			IF @v_error = 0
			BEGIN
				DELETE COLORIAGE WHERE CLR_ID = @v_clr_id
				SELECT @v_error = @@ERROR
				IF @v_error = 0
				BEGIN
					UPDATE COLORIAGE SET CLR_ORDRE = CLR_ORDRE - 1 WHERE CLR_TABLEAU = @v_vue_id AND CLR_ORDRE > @v_clr_ordre
					SELECT @v_error = @@ERROR
					IF @v_error = 0
					BEGIN
						EXEC @v_error = LIB_TRADUCTION @v_action, NULL, NULL, @v_tra_id out
						IF @v_error = 0
							SELECT @v_retour = 0
					END
				END
			END
		END
	END
	IF @v_local = 1
	BEGIN
		IF @v_error <> 0
			ROLLBACK TRAN COLORIAGE
		ELSE
			COMMIT TRAN COLORIAGE
	END
	RETURN @v_error

