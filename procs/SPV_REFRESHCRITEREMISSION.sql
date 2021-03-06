SET ANSI_NULLS OFF
SET QUOTED_IDENTIFIER OFF



-----------------------------------------------------------------------------------------
-- Procédure		: SPV_REFRESHCRITEREMISSION
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

CREATE PROCEDURE [dbo].[SPV_REFRESHCRITEREMISSION]
AS

IF 1 = 0
BEGIN
	-- This line will be executed if FMTONLY was initially set to ON
	SET FMTONLY OFF
	RETURN
END

DECLARE
	@CODE_OK tinyint,
	@CODE_KO_CRITERE_MISSION int,
	@v_codeRetour int,
	@v_misidmission int,
	@v_criidcritere int,
	@MISSION tinyint,
	@TYPE_FIXE tinyint

-- Déclaration des constantes d'états et descriptions
DECLARE
	@ETAT_TERMINE tinyint,
	@ETAT_ANNULE tinyint

-- Définition des constantes
	SELECT @CODE_OK = 0
	SELECT @CODE_KO_CRITERE_MISSION = 30
	SELECT @v_codeRetour = 0
	SELECT @MISSION = 0
	SELECT @TYPE_FIXE = 0
	SELECT @ETAT_TERMINE = 5
	SELECT @ETAT_ANNULE = 6

	BEGIN TRAN
	DELETE CRITERE_MISSION WHERE CRM_IDMISSION IN (SELECT MIS_IDMISSION FROM MISSION
		WHERE MIS_IDETAT NOT IN (@ETAT_TERMINE, @ETAT_ANNULE))
	INSERT INTO CRITERE_MISSION (CRM_IDCRITERE, CRM_IDMISSION)
		SELECT CRI_IDCRITERE, MIS_IDMISSION FROM MISSION, CRITERE WHERE MIS_IDETAT NOT IN (@ETAT_TERMINE, @ETAT_ANNULE)
		AND CRI_FAMILLE = @MISSION AND CRI_CHAMP IS NULL
	DECLARE c_critere CURSOR LOCAL SCROLL FOR SELECT CRI_IDCRITERE FROM CRITERE WHERE CRI_FAMILLE = @MISSION
		AND CRI_CHAMP IS NULL AND CRI_IDTYPE = @TYPE_FIXE
	OPEN c_critere
	DECLARE c_mission CURSOR LOCAL FAST_FORWARD FOR SELECT MIS_IDMISSION FROM MISSION
		WHERE MIS_IDETAT NOT IN (@ETAT_TERMINE, @ETAT_ANNULE)
	OPEN c_mission
	FETCH NEXT FROM c_mission INTO @v_misidmission
	WHILE ((@@FETCH_STATUS = 0) AND (@v_codeRetour = 0))
	BEGIN
		FETCH FIRST FROM c_critere INTO @v_criidcritere
		WHILE ((@@FETCH_STATUS = 0) AND (@v_codeRetour = 0))
		BEGIN
			EXEC @v_codeRetour = SPV_SETCRITEREFIXEMISSION @v_criidcritere, @v_misidmission, NULL
			IF @v_codeRetour <> @CODE_OK
				SELECT @v_codeRetour = @CODE_KO_CRITERE_MISSION
			FETCH NEXT FROM c_critere INTO @v_criidcritere
		END
		FETCH NEXT FROM c_mission INTO @v_misidmission
	END
	CLOSE c_mission
	DEALLOCATE c_mission
	CLOSE c_critere
	DEALLOCATE c_critere
	IF @v_codeRetour <> 0
		ROLLBACK TRAN
	ELSE
		COMMIT TRAN
	RETURN @v_codeRetour




