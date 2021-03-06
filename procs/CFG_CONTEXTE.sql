SET ANSI_NULLS OFF
SET QUOTED_IDENTIFIER ON


-----------------------------------------------------------------------------------------
-- Procédure		: CFG_CONTEXTE
-- Paramètre d'entrées	: @v_action : Action à mener
--			  @v_cot_id : Identifiant
--			  @v_cot_base_sys : Bas
--			  @v_cot_base_base : Base
-- Paramètre de sorties	: @v_retour : Code de retour
-- Descriptif		: Gestion des contextes
-----------------------------------------------------------------------------------------
-- Révision
-----------------------------------------------------------------------------------------
-- Date			: 12/07/2004
-- Auteur		: Cédric LE FRINGERE
-- Libellé			: Création de la procédure
-----------------------------------------------------------------------------------------
-- Date			: 08/04/2005
-- Auteur		: Cédric LE FRINGERE
-- Libellé			: Mise à jour code de retour
-----------------------------------------------------------------------------------------
-- Date			: 16/12/2005
-- Auteur		: Cédric LE FRINGERE
-- Libellé			: Ajout du test de l'unicité du contexte
-----------------------------------------------------------------------------------------

CREATE PROCEDURE [dbo].[CFG_CONTEXTE]
	@v_action smallint,
	@v_cot_id int,
	@v_cot_base_sys bigint,
	@v_cot_base_base bigint,
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
	@v_cotid int

	BEGIN TRAN
	SELECT @v_retour = 113
	SELECT @v_error = 0
	IF @v_action = 0
	BEGIN
		IF NOT EXISTS (SELECT 1 FROM CONTEXTE WHERE COT_BASE_SYS = @v_cot_base_sys AND COT_BASE_BASE = @v_cot_base_base)
		BEGIN
			INSERT INTO CONTEXTE (COT_BASE_SYS, COT_BASE_BASE)
				VALUES (@v_cot_base_sys, @v_cot_base_base)
			SELECT @v_error = @@ERROR
			IF @v_error = 0
				SELECT @v_retour = 0
		END
		ELSE
			SELECT @v_retour = 117
	END
	ELSE IF @v_action = 1
	BEGIN
		IF NOT EXISTS (SELECT 1 FROM CONTEXTE WHERE COT_ID <> @v_cot_id
			AND COT_BASE_SYS = @v_cot_base_sys AND COT_BASE_BASE = @v_cot_base_base)
		BEGIN
			IF NOT EXISTS (SELECT 1 FROM COMBINAISON, ACTION_REGLE, TYPE_ACTION_REGLE WHERE COB_IDCONTEXTE = @v_cot_id
				AND ARE_IDACTION = COB_ACTION AND TAR_IDTYPE = ARE_IDTYPE AND TAR_IDTYPE = 4 AND ARE_PARAMS = @v_cot_base_base)
			BEGIN
				UPDATE CONTEXTE SET COT_BASE_SYS = @v_cot_base_sys, COT_BASE_BASE = @v_cot_base_base
					WHERE COT_ID = @v_cot_id
				SELECT @v_error = @@ERROR
				IF @v_error = 0
					SELECT @v_retour = 0
			END
			ELSE
				SELECT @v_retour = 980
		END
		ELSE
			SELECT @v_retour = 117
	END
	ELSE IF @v_action = 2
	BEGIN
		IF NOT EXISTS (SELECT 1 FROM COMBINAISON WHERE COB_IDCONTEXTE = @v_cot_id)
		BEGIN
			DELETE CONTEXTE WHERE COT_ID = @v_cot_id
			SELECT @v_error = @@ERROR
			IF @v_error = 0
				SELECT @v_retour = 0
		END
		ELSE
			SELECT @v_retour = 114
	END
	ELSE IF @v_action = 3
	BEGIN
		DECLARE c_contexte CURSOR LOCAL FOR SELECT COT_ID FROM CONTEXTE FOR UPDATE
		OPEN c_contexte
		FETCH NEXT FROM c_contexte INTO @v_cotid
		WHILE ((@@FETCH_STATUS = 0) AND (@v_error = 0))
		BEGIN
			IF NOT EXISTS (SELECT 1 FROM COMBINAISON WHERE COB_IDCONTEXTE = @v_cotid)
			BEGIN
				DELETE CONTEXTE WHERE CURRENT OF c_contexte
				SELECT @v_error = @@ERROR
			END
			FETCH NEXT FROM c_contexte INTO @v_cotid
		END
		CLOSE c_contexte
		DEALLOCATE c_contexte
		SELECT @v_retour = 0
	END
	IF @v_error <> 0
		ROLLBACK TRAN
	ELSE
		COMMIT TRAN
	RETURN @v_error

