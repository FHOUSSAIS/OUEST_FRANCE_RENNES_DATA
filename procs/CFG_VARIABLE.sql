SET ANSI_NULLS OFF
SET QUOTED_IDENTIFIER ON



-----------------------------------------------------------------------------------------
-- Procédure		: CFG_VARIABLE
-- Paramètre d'entrées	: @v_action : Action à mener
--			  @v_var_id : Identifiant variable
--			  @v_var_type_variable : Identifiant type variable
--			  @v_var_type : Type
--			  @v_var_implementation : Implémentation
--			  @v_var_procedure : Procédure
--			  @v_var_parametre : Paramètres
--			  @v_var_libelle : Libellé
--			  @v_var_memo : Commentaire
--			  @v_lan_id : Identifiant langue
-- Paramètre de sorties	: @v_retour : Code de retour
--			  @v_tra_idlibelle : Identifiant traduction libelle
--			  @v_tra_idmemo : Identifiant traduction memo
-- Descriptif		: Gestion des variables
-----------------------------------------------------------------------------------------

CREATE PROCEDURE [dbo].[CFG_VARIABLE]
	@v_action smallint,
	@v_var_id int,
	@v_var_type_variable tinyint,
	@v_var_type bit,
	@v_var_implementation bit,
	@v_var_procedure varchar(32),
	@v_var_parametre varchar(3500),
	@v_var_libelle varchar(8000),
	@v_var_memo varchar(8000),
	@v_lan_id varchar(3),
	@v_tra_idlibelle int out,
	@v_tra_idmemo int out,
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
	@v_varid int,
	@v_varidtraductionlibelle int,
	@v_varidtraductionmemo int

	BEGIN TRAN
	SELECT @v_retour = 113
	SELECT @v_error = 0
	IF @v_action = 0
	BEGIN
		IF ((@v_var_type_variable = 3) OR ((@v_var_type_variable <> 3) AND (NOT EXISTS (SELECT 1 FROM VARIABLE WHERE VAR_TYPE_VARIABLE = @v_var_type_variable
			AND VAR_PARAMETRE = @v_var_parametre)))) AND NOT EXISTS (SELECT 1 FROM VARIABLE, LIBELLE WHERE LIB_LANGUE = @v_lan_id AND LIB_TRADUCTION = VAR_IDTRADUCTIONLIBELLE AND LIB_LIBELLE = @v_var_libelle)
		BEGIN
			EXEC @v_error = LIB_TRADUCTION @v_action, @v_lan_id, @v_var_libelle, @v_tra_idlibelle out
			IF @v_error = 0
			BEGIN
				EXEC @v_error = LIB_TRADUCTION @v_action, @v_lan_id, @v_var_memo, @v_tra_idmemo out
				IF @v_error = 0
				BEGIN
					INSERT INTO VARIABLE (VAR_ID, VAR_TYPE_VARIABLE, VAR_IDTRADUCTIONLIBELLE, VAR_IDTRADUCTIONMEMO, VAR_SYSTEME, VAR_TYPE,
						VAR_IMPLEMENTATION, VAR_PROCEDURE, VAR_PARAMETRE, VAR_TRADUCTIONTEXTE) SELECT (SELECT CASE SIGN(MIN(VAR_ID)) WHEN -1 THEN MIN(VAR_ID) - 1 ELSE -1 END FROM VARIABLE),
						@v_var_type_variable, @v_tra_idlibelle, @v_tra_idmemo, 0, @v_var_type, @v_var_implementation, @v_var_procedure, @v_var_parametre, @v_tra_idtexte
					SELECT @v_error = @@ERROR
					IF @v_error = 0
						SELECT @v_retour = 0
				END
			END
		END
		ELSE
			SELECT @v_retour = 117
	END
	ELSE IF @v_action = 1
	BEGIN
		IF NOT EXISTS (SELECT 1 FROM VARIABLE, LIBELLE WHERE LIB_LANGUE = @v_lan_id AND LIB_TRADUCTION = VAR_IDTRADUCTIONLIBELLE AND LIB_LIBELLE = @v_var_libelle AND VAR_ID <> @v_var_id)
		BEGIN
			UPDATE LIBELLE SET LIB_LIBELLE = @v_var_libelle WHERE LIB_LANGUE = @v_lan_id AND LIB_TRADUCTION = @v_tra_idlibelle
			SELECT @v_error = @@ERROR
			IF @v_error = 0
			BEGIN
				UPDATE LIBELLE SET LIB_LIBELLE = @v_var_memo WHERE LIB_LANGUE = @v_lan_id AND LIB_TRADUCTION = @v_tra_idmemo
				SELECT @v_error = @@ERROR
				IF @v_error = 0
				BEGIN
					UPDATE VARIABLE SET VAR_TYPE_VARIABLE = @v_var_type_variable, VAR_TYPE = @v_var_type, VAR_IMPLEMENTATION = @v_var_implementation,
						VAR_PROCEDURE = @v_var_procedure, VAR_PARAMETRE = @v_var_parametre, VAR_TRADUCTIONTEXTE = @v_tra_idtexte WHERE VAR_ID = @v_var_id
					SELECT @v_error = @@ERROR
					IF @v_error = 0
						SELECT @v_retour = 0
				END
			END
		END
		ELSE
			SELECT @v_retour = 117
	END
	ELSE IF @v_action = 2
	BEGIN
		IF NOT EXISTS (SELECT 1 FROM CONDITION WHERE CDT_VARIABLE = @v_var_id)
		BEGIN
			DELETE VARIABLE WHERE VAR_ID = @v_var_id
			SELECT @v_error = @@ERROR
			IF @v_error = 0
			BEGIN
				EXEC @v_error = LIB_TRADUCTION @v_action, NULL, NULL, @v_tra_idlibelle out
				IF @v_error = 0
				BEGIN
					EXEC @v_error = LIB_TRADUCTION @v_action, NULL, NULL, @v_tra_idmemo out
					IF @v_error = 0
						SELECT @v_retour = 0
				END
			END
		END
		ELSE
			SELECT @v_retour = 114
	END
	ELSE IF @v_action = 3
	BEGIN
		DECLARE c_variable CURSOR LOCAL FOR SELECT VAR_ID, VAR_IDTRADUCTIONLIBELLE, VAR_IDTRADUCTIONMEMO FROM VARIABLE WHERE VAR_SYSTEME = 0 FOR UPDATE
		OPEN c_variable
		FETCH NEXT FROM c_variable INTO @v_varid, @v_varidtraductionlibelle, @v_varidtraductionmemo
		WHILE ((@@FETCH_STATUS = 0) AND (@v_error = 0))
		BEGIN
			IF NOT EXISTS (SELECT 1 FROM CONDITION WHERE CDT_VARIABLE = @v_varid)
			BEGIN
				DELETE VARIABLE WHERE CURRENT OF c_variable
				SELECT @v_error = @@ERROR
				IF @v_error = 0
				BEGIN
					EXEC @v_error = LIB_TRADUCTION @v_action, NULL, NULL, @v_varidtraductionlibelle out
					IF @v_error = 0
						EXEC @v_error = LIB_TRADUCTION @v_action, NULL, NULL, @v_varidtraductionmemo out
				END
			END
			FETCH NEXT FROM c_variable INTO @v_varid, @v_varidtraductionlibelle, @v_varidtraductionmemo
		END
		CLOSE c_variable
		DEALLOCATE c_variable
		SELECT @v_retour = 0
	END
	IF @v_error <> 0
		ROLLBACK TRAN
	ELSE
		COMMIT TRAN
	RETURN @v_error

