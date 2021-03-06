SET ANSI_NULLS OFF
SET QUOTED_IDENTIFIER ON


-----------------------------------------------------------------------------------------
-- Procédure		: CFG_CONDITION
-- Paramètre d'entrées	: @v_action : Action à mener
--			  @v_cdt_idcondition : Identifiant
--			  @v_cdt_idcritere : Critère
--			  @v_cdt_variable : Variable
--			  @v_cdt_idoperateur : Opérateur
--			  @v_cdt_valeur : Valeur
--			  @v_tra_idtexte : Identifiant texte
-- Paramètre de sorties	: @v_retour : Code de retour
-- Descriptif		: Gestion des filtres
-----------------------------------------------------------------------------------------

CREATE PROCEDURE [dbo].[CFG_CONDITION]
	@v_action smallint,
	@v_cdt_idcondition int,
	@v_cdt_idcritere int,
	@v_cdt_variable int,
	@v_cdt_idoperateur tinyint,
	@v_cdt_valeur varchar(4000),
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
	@v_cdtidcondition int

	BEGIN TRAN
	SELECT @v_retour = 113
	SELECT @v_error = 0
	IF @v_action = 0
	BEGIN
		IF (@v_cdt_idcritere IS NOT NULL)
		BEGIN
			IF NOT EXISTS (SELECT 1 FROM CONDITION WHERE CDT_IDCRITERE = @v_cdt_idcritere
				AND CDT_IDOPERATEUR = @v_cdt_idoperateur AND CDT_VALEUR = @v_cdt_valeur)
			BEGIN
				INSERT INTO CONDITION (CDT_IDCONDITION, CDT_IDCRITERE, CDT_IDOPERATEUR, CDT_VALEUR, CDT_IDTRADUCTIONTEXTE, CDT_SYSTEME)
					SELECT (SELECT CASE SIGN(MIN(CDT_IDCONDITION)) WHEN -1 THEN MIN(CDT_IDCONDITION) - 1 ELSE -1 END FROM CONDITION),
					@v_cdt_idcritere, @v_cdt_idoperateur, @v_cdt_valeur, @v_tra_idtexte, 0
				SELECT @v_error = @@ERROR
				IF @v_error = 0
					SELECT @v_retour = 0
			END
			ELSE
				SELECT @v_retour = 117
		END
		ELSE IF (@v_cdt_variable IS NOT NULL)
		BEGIN
			IF NOT EXISTS (SELECT 1 FROM CONDITION WHERE CDT_VARIABLE = @v_cdt_variable
				AND CDT_IDOPERATEUR = @v_cdt_idoperateur AND CDT_VALEUR = @v_cdt_valeur)
			BEGIN
				INSERT INTO CONDITION (CDT_IDCONDITION, CDT_VARIABLE, CDT_IDOPERATEUR, CDT_VALEUR, CDT_IDTRADUCTIONTEXTE, CDT_SYSTEME)
					SELECT (SELECT CASE SIGN(MIN(CDT_IDCONDITION)) WHEN -1 THEN MIN(CDT_IDCONDITION) - 1 ELSE -1 END FROM CONDITION),
					@v_cdt_variable, @v_cdt_idoperateur, @v_cdt_valeur, @v_tra_idtexte, 0
				SELECT @v_error = @@ERROR
				IF @v_error = 0
					SELECT @v_retour = 0
			END
			ELSE
				SELECT @v_retour = 117
		END
	END
	ELSE IF @v_action = 1
	BEGIN
		IF (@v_cdt_idcritere IS NOT NULL)
		BEGIN
			IF NOT EXISTS (SELECT 1 FROM CONDITION WHERE CDT_IDCONDITION <> @v_cdt_idcondition AND CDT_IDCRITERE = @v_cdt_idcritere
				AND CDT_IDOPERATEUR = @v_cdt_idoperateur AND CDT_VALEUR = @v_cdt_valeur)
			BEGIN
				UPDATE CONDITION SET CDT_IDCRITERE = @v_cdt_idcritere, CDT_IDOPERATEUR = @v_cdt_idoperateur,
					CDT_VALEUR = @v_cdt_valeur, CDT_IDTRADUCTIONTEXTE = @v_tra_idtexte
					WHERE CDT_IDCONDITION = @v_cdt_idcondition
				SELECT @v_error = @@ERROR
				IF @v_error = 0
					SELECT @v_retour = 0
			END
			ELSE
				SELECT @v_retour = 117
		END
		ELSE IF (@v_cdt_variable IS NOT NULL)
		BEGIN
			IF NOT EXISTS (SELECT 1 FROM CONDITION WHERE CDT_IDCONDITION <> @v_cdt_idcondition AND CDT_VARIABLE = @v_cdt_variable
				AND CDT_IDOPERATEUR = @v_cdt_idoperateur AND CDT_VALEUR = @v_cdt_valeur)
			BEGIN
				UPDATE CONDITION SET CDT_VARIABLE = @v_cdt_variable, CDT_IDOPERATEUR = @v_cdt_idoperateur,
					CDT_VALEUR = @v_cdt_valeur, CDT_IDTRADUCTIONTEXTE = @v_tra_idtexte
					WHERE CDT_IDCONDITION = @v_cdt_idcondition
				SELECT @v_error = @@ERROR
				IF @v_error = 0
					SELECT @v_retour = 0
			END
			ELSE
				SELECT @v_retour = 117
		END
	END
	ELSE IF @v_action = 2
	BEGIN
		IF NOT EXISTS (SELECT 1 FROM LISTE_CONDITION WHERE LCN_IDCONDITION = @v_cdt_idcondition)
		BEGIN
			DELETE CONDITION WHERE CDT_IDCONDITION = @v_cdt_idcondition
			SELECT @v_error = @@ERROR
			IF @v_error = 0
				SELECT @v_retour = 0
		END
		ELSE
			SELECT @v_retour = 114
	END
	ELSE IF @v_action = 3
	BEGIN
		DECLARE c_condition CURSOR LOCAL FOR SELECT CDT_IDCONDITION FROM CONDITION WHERE CDT_SYSTEME = 0 FOR UPDATE
		OPEN c_condition
		FETCH NEXT FROM c_condition INTO @v_cdtidcondition
		WHILE ((@@FETCH_STATUS = 0) AND (@v_error = 0))
		BEGIN
			IF NOT EXISTS (SELECT 1 FROM LISTE_CONDITION WHERE LCN_IDCONDITION = @v_cdtidcondition)
			BEGIN
				DELETE CONDITION WHERE CURRENT OF c_condition
				SELECT @v_error = @@ERROR
			END
			FETCH NEXT FROM c_condition INTO @v_cdtidcondition
		END
		CLOSE c_condition
		DEALLOCATE c_condition
		SELECT @v_retour = 0
	END
	IF @v_error <> 0
		ROLLBACK TRAN
	ELSE
		COMMIT TRAN
	RETURN @v_error

