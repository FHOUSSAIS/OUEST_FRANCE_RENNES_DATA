SET ANSI_NULLS OFF
SET QUOTED_IDENTIFIER OFF

-----------------------------------------------------------------------------------------
-- Procédure		: SPV_POINTACTION
-- Paramètre d'entrée	: @v_iag_idagv : Identifiant AGV
--						  @v_idaction : Identifiant action
--						  @v_parametre : Paramètre
-- Paramètre de sortie	: Valeur de retour :
--			    @CODE_OK : Réussite
--			    @CODE_KO : Echec
--			    @CODE_KO_INCONNU : Action inconnue
--				@CODE_KO_INCORRECT : Configuration incorrecte
--				@CODE_KO_SQL : Erreur SQL
-- Descriptif		: Exécution de l'action liée aux points actions
-----------------------------------------------------------------------------------------

CREATE PROCEDURE [dbo].[SPV_POINTACTION]
	@v_iag_idagv tinyint,
	@v_idaction int,
	@v_parametre varchar(8000)
AS

IF 1 = 0
BEGIN
	-- This line will be executed if FMTONLY was initially set to ON
	SET FMTONLY OFF
	RETURN
END

-- Déclaration des variables
DECLARE
	@v_error int,
	@v_status int,
	@v_retour int,
	@v_por_id int,
	@v_por_service bit,
	@v_sas_id int,
	@v_local bit,
	@v_transaction varchar(32)
	
-- Déclaration des constantes de retour
DECLARE
	@CODE_OK tinyint,
	@CODE_KO tinyint,
	@CODE_KO_INCONNU tinyint,
	@CODE_KO_INCORRECT tinyint,
	@CODE_KO_SQL tinyint

-- Déclaration des constantes d'action
DECLARE
	@ACTI_OUVERTURE_PORTE tinyint,
	@ACTI_FERMETURE_PORTE tinyint
	
-- Définition des constantes
	SET @CODE_OK = 0
	SET @CODE_KO = 1
	SET @CODE_KO_INCONNU = 7
	SET @CODE_KO_INCORRECT = 11
	SET @CODE_KO_SQL = 13
	SET @ACTI_OUVERTURE_PORTE = 1
	SET @ACTI_FERMETURE_PORTE = 2

-- Initialisation des variables
	SET @v_error = 0
	SET @v_status = @CODE_OK
	SET @v_retour = @CODE_KO	
	SET @v_transaction = 'SPV_POINTACTION'


	IF @@TRANCOUNT > 0
		SET @v_local = 0
	ELSE
	BEGIN
		SET @v_local = 1
		BEGIN TRAN @v_transaction
	END

	IF @v_idaction IN (@ACTI_OUVERTURE_PORTE, @ACTI_FERMETURE_PORTE)
	BEGIN
		SELECT @v_por_id = POR_ID, @v_por_service = POR_SERVICE FROM PORTE WHERE POR_ID = @v_parametre
		IF @v_por_id IS NOT NULL
		BEGIN
			IF @v_idaction = @ACTI_OUVERTURE_PORTE
			BEGIN
				IF NOT EXISTS (SELECT 1 FROM ASSOCIATION_INFO_AGV_PORTE WHERE AIP_PORTE = @v_por_id AND AIP_INFO_AGV = @v_iag_idagv)
					INSERT INTO ASSOCIATION_INFO_AGV_PORTE (AIP_PORTE, AIP_INFO_AGV, AIP_ORDRE, AIP_AUTORISATION, AIP_INDEX) SELECT @v_por_id, @v_iag_idagv,
						ISNULL(MAX(AIP_ORDRE) + 1, 1), 0, 1 FROM ASSOCIATION_INFO_AGV_PORTE WHERE AIP_PORTE = @v_por_id
				ELSE
					UPDATE ASSOCIATION_INFO_AGV_PORTE SET AIP_INDEX = AIP_INDEX + 1 WHERE AIP_PORTE = @v_por_id AND AIP_INFO_AGV = @v_iag_idagv
				SET @v_error = @@ERROR
			END
			ELSE
			BEGIN
				SELECT @v_sas_id = A.APS_SAS FROM ASSOCIATION_PORTE_SAS A WHERE A.APS_PORTE = @v_por_id
					AND EXISTS (SELECT 1 FROM ASSOCIATION_PORTE_SAS B INNER JOIN PORTE ON POR_ID = B.APS_PORTE
					WHERE B.APS_SAS = A.APS_SAS AND B.APS_PORTE <> @v_por_id AND POR_SERVICE = 1)
				IF @v_por_service = 0 OR @v_sas_id IS NULL
				BEGIN
					IF EXISTS (SELECT 1 FROM ASSOCIATION_INFO_AGV_PORTE WHERE AIP_PORTE = @v_por_id AND AIP_INFO_AGV = @v_iag_idagv AND AIP_INDEX = 1)
						DELETE ASSOCIATION_INFO_AGV_PORTE WHERE AIP_PORTE = @v_por_id AND AIP_INFO_AGV = @v_iag_idagv
					ELSE
						UPDATE ASSOCIATION_INFO_AGV_PORTE SET AIP_INDEX = AIP_INDEX - 1 WHERE AIP_PORTE = @v_por_id AND AIP_INFO_AGV = @v_iag_idagv
					SET @v_error = @@ERROR
				END
				ELSE IF @v_sas_id IS NOT NULL
				BEGIN
					IF EXISTS (SELECT 1 FROM ASSOCIATION_INFO_AGV_PORTE INNER JOIN ASSOCIATION_PORTE_SAS ON APS_PORTE = AIP_PORTE
						WHERE AIP_INFO_AGV = @v_iag_idagv AND APS_SAS = @v_sas_id AND ((AIP_PORTE = @v_por_id AND AIP_INDEX = 1) OR (AIP_PORTE <> @v_por_id AND AIP_INDEX = 0)) HAVING COUNT(*) = 2)
						DELETE ASSOCIATION_INFO_AGV_PORTE WHERE AIP_PORTE IN (SELECT APS_PORTE FROM ASSOCIATION_PORTE_SAS WHERE APS_SAS = @v_sas_id) AND AIP_INFO_AGV = @v_iag_idagv
					ELSE
						UPDATE ASSOCIATION_INFO_AGV_PORTE SET AIP_INDEX = AIP_INDEX - 1, AIP_AUTORISATION = CASE AIP_INDEX WHEN 1 THEN 0 ELSE 1 END WHERE AIP_PORTE = @v_por_id AND AIP_INFO_AGV = @v_iag_idagv
					SET @v_error = @@ERROR
				END
			END
			IF @v_error = 0
			BEGIN
				EXEC @v_status = SPV_PORTE @v_action = @v_idaction, @v_por_id = @v_por_id, @v_agv = @v_iag_idagv
				SET @v_error = @@ERROR
				IF @v_status = @CODE_OK AND @v_error = 0
					SET @v_retour = @CODE_OK
				ELSE
					SET @v_retour = CASE @v_status WHEN @CODE_OK THEN @v_error ELSE @v_status END
			END
			ELSE
				SET @v_retour = @CODE_KO_SQL
		END
		ELSE
			SET @v_retour = @CODE_KO_INCORRECT
	END
	ELSE
		SET @v_retour = @CODE_KO_INCONNU
	
	IF @v_local = 1
	BEGIN
		IF @v_retour = @CODE_OK
			COMMIT TRAN @v_transaction
		ELSE
			ROLLBACK TRAN @v_transaction
	END

	RETURN @v_retour

