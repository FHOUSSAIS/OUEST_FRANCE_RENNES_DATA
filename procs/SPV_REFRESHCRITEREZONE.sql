SET ANSI_NULLS OFF
SET QUOTED_IDENTIFIER OFF




-----------------------------------------------------------------------------------------
-- Procédure		: SPV_REFRESHCRITEREZONE
-- Paramètre d'entrée	: 
-- Paramètre de sortie	: 
-- Descriptif		: Evaluation des critères de missions au lancement de Logistic Core
-----------------------------------------------------------------------------------------
-- Révision
-----------------------------------------------------------------------------------------
-- Date			: 19/04/2006
-- Auteur		: Cédric LE FRINGERE
-- Libellé			: Création de la procédure
-----------------------------------------------------------------------------------------
-- Date			: 18/06/2007
-- Auteur		: Cédric LE FRINGERE
-- Libellé			: Standardisation Logistic Core
-----------------------------------------------------------------------------------------

CREATE PROCEDURE [dbo].[SPV_REFRESHCRITEREZONE]
AS

IF 1 = 0
BEGIN
	-- This line will be executed if FMTONLY was initially set to ON
	SET FMTONLY OFF
	RETURN
END

DECLARE
	@CODE_OK tinyint,
	@CODE_KO_CRITERE_ZONE int,
	@v_codeRetour int,
	@v_zneidzone int,
	@v_criidcritere int,
	@ZONE tinyint,
	@TYPE_FIXE tinyint

	BEGIN TRAN
	SELECT @CODE_OK = 0
	SELECT @CODE_KO_CRITERE_ZONE = 33
	SELECT @v_codeRetour = 0
	SELECT @ZONE = 1
	SELECT @TYPE_FIXE = 0
	DELETE CRITERE_ZONE
	INSERT INTO CRITERE_ZONE (CRZ_IDCRITERE, CRZ_IDZONE)
		SELECT CRI_IDCRITERE, ZNE_ID FROM ZONE, CRITERE WHERE CRI_FAMILLE = @ZONE
		AND CRI_CHAMP IS NULL
	DECLARE c_critere CURSOR LOCAL SCROLL FOR SELECT CRI_IDCRITERE FROM CRITERE WHERE CRI_FAMILLE = @ZONE
		AND CRI_CHAMP IS NULL AND CRI_IDTYPE = @TYPE_FIXE
	OPEN c_critere
	DECLARE c_zone CURSOR LOCAL FAST_FORWARD FOR SELECT ZNE_ID FROM ZONE
	OPEN c_zone
	FETCH NEXT FROM c_zone INTO @v_zneidzone
	WHILE ((@@FETCH_STATUS = 0) AND (@v_codeRetour = 0))
	BEGIN
		FETCH FIRST FROM c_critere INTO @v_criidcritere
		WHILE ((@@FETCH_STATUS = 0) AND (@v_codeRetour = 0))
		BEGIN
			EXEC @v_codeRetour = SPV_SETCRITEREFIXEZONE @v_criidcritere, @v_zneidzone, NULL
			IF @v_codeRetour <> @CODE_OK
				SELECT @v_codeRetour = @CODE_KO_CRITERE_ZONE
			FETCH NEXT FROM c_critere INTO @v_criidcritere
		END
		FETCH NEXT FROM c_zone INTO @v_zneidzone
	END
	CLOSE c_zone
	DEALLOCATE c_zone
	CLOSE c_critere
	DEALLOCATE c_critere
	IF @v_codeRetour <> 0
		ROLLBACK TRAN
	ELSE
		COMMIT TRAN
	RETURN @v_codeRetour


