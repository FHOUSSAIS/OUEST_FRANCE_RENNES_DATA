SET ANSI_NULLS OFF
SET QUOTED_IDENTIFIER ON



-----------------------------------------------------------------------------------------
-- Procédure		: CFG_ACTION
-- Paramètre d'entrées	: @v_action : Action à mener
--			  @v_are_idaction : Identifiant
--			  @v_are_idtype : Type de l'action
--			  @v_are_params : Paramètres
--			  @v_are_libelle : Libelle
--			  @v_lan_id : Identifiant langue
--			  @v_tra_idtexte : Identifiant texte
-- Paramètre de sorties	: @v_retour : Code de retour
--			  @v_tra_id : Identifiant traduction
-- Descriptif		: Gestion des actions
-----------------------------------------------------------------------------------------

CREATE PROCEDURE [dbo].[CFG_ACTION]
	@v_action smallint,
	@v_are_idaction int,
	@v_are_idtype int,
	@v_are_implementation bit,
	@v_are_procedure varchar(32),
	@v_are_params varchar(3500),
	@v_are_libelle varchar(8000),
	@v_lan_id varchar(3),
	@v_tra_idlibelle int out,
	@v_tra_idtexte int,
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
	@v_areidaction int,
	@v_areidtraduction int

	BEGIN TRAN
	SELECT @v_retour = 113
	SELECT @v_error = 0
	IF @v_action = 0
	BEGIN
		IF ((@v_are_idtype = 6) OR ((@v_are_idtype <> 6) AND (NOT EXISTS (SELECT 1 FROM ACTION_REGLE WHERE ARE_IDTYPE = @v_are_idtype
			AND ARE_PARAMS = @v_are_params))))
		BEGIN
			EXEC @v_error = LIB_TRADUCTION @v_action, @v_lan_id, @v_are_libelle, @v_tra_idlibelle out
			IF @v_error = 0
			BEGIN
				INSERT INTO ACTION_REGLE (ARE_IDACTION, ARE_IDTYPE, ARE_PARAMS, ARE_IDTRADUCTIONLIBELLE, ARE_IDTRADUCTIONTEXTE, ARE_SYSTEME,
					ARE_IMPLEMENTATION, ARE_PROCEDURE) SELECT (SELECT CASE SIGN(MIN(ARE_IDACTION)) WHEN -1 THEN MIN(ARE_IDACTION) - 1 ELSE -1 END FROM ACTION_REGLE),
					@v_are_idtype, @v_are_params, @v_tra_idlibelle, @v_tra_idtexte, 0, @v_are_implementation, @v_are_procedure
				SELECT @v_error = @@ERROR
				IF @v_error = 0
					SELECT @v_retour = 0
			END
		END
		ELSE
			SELECT @v_retour = 117
	END
	ELSE IF @v_action = 1
	BEGIN
		IF ((@v_are_idtype = 6) OR ((@v_are_idtype <> 6) AND (NOT EXISTS (SELECT 1 FROM ACTION_REGLE WHERE ARE_IDACTION <> @v_are_idaction AND ARE_IDTYPE = @v_are_idtype
			AND ((ARE_PARAMS = @v_are_params AND @v_are_params IS NOT NULL) OR (ARE_PARAMS IS NULL AND @v_are_params IS NULL))))))
		BEGIN
			IF ((@v_are_idtype <> 4) OR (@v_are_idtype = 4 AND NOT EXISTS (SELECT 1 FROM COMBINAISON, CONTEXTE WHERE COB_ACTION = @v_are_idaction
				AND COT_ID = COB_IDCONTEXTE AND COT_BASE_BASE = @v_are_params)))
			BEGIN
				UPDATE LIBELLE SET LIB_LIBELLE = @v_are_libelle WHERE LIB_LANGUE = @v_lan_id AND LIB_TRADUCTION = @v_tra_idlibelle
				SELECT @v_error = @@ERROR
				IF @v_error = 0
				BEGIN
					UPDATE ACTION_REGLE SET ARE_IDTYPE = @v_are_idtype, ARE_PARAMS = @v_are_params, ARE_IDTRADUCTIONTEXTE = @v_tra_idtexte,
						ARE_IMPLEMENTATION = @v_are_implementation, ARE_PROCEDURE = @v_are_procedure
						WHERE ARE_IDACTION = @v_are_idaction
					SELECT @v_error = @@ERROR
					IF @v_error = 0
						SELECT @v_retour = 0
				END
			END
			ELSE
				SELECT @v_retour = 980
		END
		ELSE
			SELECT @v_retour = 117
	END
	ELSE IF @v_action = 2
	BEGIN
		IF NOT EXISTS ((SELECT 1 FROM COMBINAISON_DE_REGLE WHERE CDR_IDACTION = @v_are_idaction)
			UNION (SELECT 1 FROM COMBINAISON WHERE COB_ACTION = @v_are_idaction))
		BEGIN
			DELETE ACTION_REGLE WHERE ARE_IDACTION = @v_are_idaction
			SELECT @v_error = @@ERROR
			IF @v_error = 0
			BEGIN
				EXEC @v_error = LIB_TRADUCTION @v_action, NULL, NULL, @v_tra_idlibelle out
				IF @v_error = 0
					SELECT @v_retour = 0
			END
		END
		ELSE
			SELECT @v_retour = 114
	END
	ELSE IF @v_action = 3
	BEGIN
		DECLARE c_action CURSOR LOCAL FOR SELECT ARE_IDACTION, ARE_IDTRADUCTIONLIBELLE FROM ACTION_REGLE WHERE ARE_SYSTEME = 0 FOR UPDATE
		OPEN c_action
		FETCH NEXT FROM c_action INTO @v_areidaction, @v_areidtraduction
		WHILE ((@@FETCH_STATUS = 0) AND (@v_error = 0))
		BEGIN
			IF NOT EXISTS ((SELECT 1 FROM COMBINAISON_DE_REGLE WHERE CDR_IDACTION = @v_areidaction)
				UNION (SELECT 1 FROM COMBINAISON WHERE COB_ACTION = @v_areidaction))
			BEGIN
				DELETE ACTION_REGLE WHERE CURRENT OF c_action
				SELECT @v_error = @@ERROR
				IF @v_error = 0
					EXEC @v_error = LIB_TRADUCTION @v_action, NULL, NULL, @v_areidtraduction out
			END
			FETCH NEXT FROM c_action INTO @v_areidaction, @v_areidtraduction
		END
		CLOSE c_action
		DEALLOCATE c_action
		SELECT @v_retour = 0
	END
	IF @v_error <> 0
		ROLLBACK TRAN
	ELSE
		COMMIT TRAN
	RETURN @v_error

