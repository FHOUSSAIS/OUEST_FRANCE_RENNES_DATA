SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
-- =============================================
-- Description:	Modification de la position du skate d'entrée
	-- @v_idLigne			: Identifiant de ligne
	-- @v_sensenroulement	: Sens Enroulement
	-- @v_idbobine			: ID bobine
-- =============================================
CREATE PROCEDURE [dbo].[SPC_DMC_DEPOSERBOBINE]
	@v_idLigne			INT,
	@v_sensEnroulement	INT,
	@v_idbobine			INT
AS
BEGIN

DECLARE @CODE_OK INT = 0
DECLARE	@CODE_KO INT = 1

DECLARE @ACTION_DEPOSER_BOBINE INT = 21

DECLARE @retour INT = @CODE_OK
DECLARE @procStock VARCHAR(128) = OBJECT_NAME(@@PROCID)
DECLARE @moniteur VARCHAR(128) = 'Gestionnaire Demaculeuse'
DECLARE @trace VARCHAR(7500)
DECLARE @local INT = 0

DECLARE @variableAutomate_sensEnroulement INT
DECLARE @variableAutomate_idBobine1 INT
DECLARE @variableAutomate_idBobine2 INT
DECLARE @idBobineToChar1 VARCHAR(8) 
DECLARE @idBobineToChar2 VARCHAR(8)

SET @trace = 'SPC_DMC_GET_IDBOBINE ' 
						+ ' @v_idLigne = ' + ISNULL(CONVERT(VARCHAR, @v_idLigne), 'NULL')	
						+ ', @v_sensEnroulement = ' + ISNULL(CONVERT(VARCHAR, @v_sensEnroulement), 'NULL')	
						+ ', @v_idbobine = ' + ISNULL(CONVERT(VARCHAR, @v_idbobine), 'NULL')	
SET @trace = @procStock + '/' + @trace
EXEC INT_ADDTRACESPECIFIQUE	@v_mon_idmoniteur = @moniteur,
							@v_log_idlog = 'DEBUG',
							@v_trace = @trace

/*Récupération des ID des mots automates*/
SELECT
	@variableAutomate_sensEnroulement = dbo.SPC_ASSOCIATION_LIGNE_VARIABLEAUTOMATE.SLV_SENSENROULEMENT,
	@variableAutomate_idBobine1 = dbo.SPC_ASSOCIATION_LIGNE_VARIABLEAUTOMATE.SLV_IDBOBINE1,
	@variableAutomate_idBobine2 = dbo.SPC_ASSOCIATION_LIGNE_VARIABLEAUTOMATE.SLV_IDBOBINE2
FROM SPC_ASSOCIATION_LIGNE_VARIABLEAUTOMATE
WHERE SLV_IDLIGNE = @v_idLigne
AND SLV_ACTION = @ACTION_DEPOSER_BOBINE

-- Création de l'identifiant Bobine en 2 infos 
EXEC @retour = SPC_DMC_GET_IDBOBINE	@v_idBobine = @v_idbobine,
									@v_idBobineToChar1 = @idBobineToChar1 OUTPUT,
									@v_idBobineToChar2 = @idBobineToChar2 OUTPUT
IF(@retour <> @CODE_OK)
BEGIN
	SET @trace = 'SPC_DMC_GET_IDBOBINE ' + ISNULL(CONVERT(VARCHAR, @v_idbobine), 'NULL')
						+ ', @v_idBobineToChar1 = ' + ISNULL(CONVERT(VARCHAR, @idBobineToChar1), 'NULL')	
						+ ', @v_idBobineToChar2 = ' + ISNULL(CONVERT(VARCHAR, @idBobineToChar2), 'NULL')	
	SET @trace = @procStock + '/' + @trace
	EXEC INT_ADDTRACESPECIFIQUE	@v_mon_idmoniteur = @moniteur,
								@v_log_idlog = 'ERREUR',
								@v_trace = @trace
END


IF(@retour = @CODE_OK)
BEGIN
	-- Envoi Sens Enroulement
	IF(@v_sensenroulement IS NOT NULL)
	BEGIN
		EXEC @retour = INT_SETVARIABLEAUTOMATE	@v_vau_idvariableautomate = @variableAutomate_sensEnroulement,
												@v_vau_valeur = @v_sensenroulement
	END
	ELSE
	BEGIN
		SET @retour = @CODE_KO
	END
	IF(@retour <> @CODE_OK)
	BEGIN
		SET @trace = 'INT_SETVARIABLEAUTOMATE ' + ISNULL(CONVERT(VARCHAR, @retour), 'NULL')
							+ ', @v_vau_idvariableautomate = ' + ISNULL(CONVERT(VARCHAR, @variableAutomate_sensEnroulement), 'NULL')	
							+ ', @v_vau_valeur = ' + ISNULL(CONVERT(VARCHAR, @v_sensenroulement), 'NULL')	
		SET @trace = @procStock + '/' + @trace
		EXEC INT_ADDTRACESPECIFIQUE	@v_mon_idmoniteur = @moniteur,
									@v_log_idlog = 'ERREUR',
									@v_trace = @trace
	END
	ELSE
	BEGIN
		SET @trace = 'Information Sens Enroulement Envoyée'
		SET @trace = @procStock + '/' + @trace
		EXEC INT_ADDTRACESPECIFIQUE	@v_mon_idmoniteur = @moniteur,
									@v_log_idlog = 'DEBUG',
									@v_trace = @trace
	END
END

IF(@retour = @CODE_OK)
BEGIN
	-- Envoi Id Bobine 1
	IF(@idBobineToChar1 IS NOT NULL)
	BEGIN
		EXEC @retour = INT_SETVARIABLEAUTOMATE	@v_vau_idvariableautomate = @variableAutomate_idBobine1,
												@v_vau_valeur = @idBobineToChar1
	END
	ELSE
	BEGIN
		SET @retour = @CODE_KO
	END
	IF(@retour <> @CODE_OK)
	BEGIN
		SET @trace = 'INT_SETVARIABLEAUTOMATE ' + ISNULL(CONVERT(VARCHAR, @retour), 'NULL')
							+ ', @v_vau_idvariableautomate = ' + ISNULL(CONVERT(VARCHAR, @variableAutomate_idBobine1), 'NULL')	
							+ ', @v_vau_valeur = ' + ISNULL(CONVERT(VARCHAR, @idBobineToChar1), 'NULL')	
		SET @trace = @procStock + '/' + @trace
		EXEC INT_ADDTRACESPECIFIQUE	@v_mon_idmoniteur = @moniteur,
									@v_log_idlog = 'ERREUR',
									@v_trace = @trace
	END
	ELSE
	BEGIN
		SET @trace = 'Information Bobine 1 Envoyée'
		SET @trace = @procStock + '/' + @trace
		EXEC INT_ADDTRACESPECIFIQUE	@v_mon_idmoniteur = @moniteur,
									@v_log_idlog = 'DEBUG',
									@v_trace = @trace
	END
END

IF(@retour = @CODE_OK)
BEGIN									
	-- Envoi Id Bobine 2
	IF(@idBobineToChar2 IS NOT NULL)
	BEGIN
		EXEC @retour = INT_SETVARIABLEAUTOMATE	@v_vau_idvariableautomate = @variableAutomate_idBobine2,
												@v_vau_valeur = @idBobineToChar2
	END
	ELSE
	BEGIN
		SET @retour = @CODE_KO
	END										
	IF(@retour <> @CODE_OK)
	BEGIN
		SET @trace = 'INT_SETVARIABLEAUTOMATE ' + ISNULL(CONVERT(VARCHAR, @retour), 'NULL')
							+ ', @v_vau_idvariableautomate = ' + ISNULL(CONVERT(VARCHAR, @variableAutomate_idBobine2), 'NULL')	
							+ ', @v_vau_valeur = ' + ISNULL(CONVERT(VARCHAR, @idBobineToChar2), 'NULL')	
		SET @trace = @procStock + '/' + @trace
		EXEC INT_ADDTRACESPECIFIQUE	@v_mon_idmoniteur = @moniteur,
									@v_log_idlog = 'ERREUR',
									@v_trace = @trace
	END
	ELSE
	BEGIN
		SET @trace = 'Information Bobine 2 Envoyée'
		SET @trace = @procStock + '/' + @trace
		EXEC INT_ADDTRACESPECIFIQUE	@v_mon_idmoniteur = @moniteur,
									@v_log_idlog = 'DEBUG',
									@v_trace = @trace
	END
END

RETURN @retour

END


