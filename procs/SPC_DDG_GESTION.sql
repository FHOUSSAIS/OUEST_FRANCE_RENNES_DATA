SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
-- =============================================
-- Description:	Supprimer une demande
-- @v_idDemande	: Id de demande 
-- =============================================
CREATE PROCEDURE [dbo].[SPC_DDG_GESTION]
AS
BEGIN

declare @CODE_OK int = 0
declare	@CODE_KO int = 1

set @CODE_OK = 0
set @CODE_KO = 1

DECLARE @retour INT = @CODE_OK
DECLARE @procStock VARCHAR(128) = OBJECT_NAME(@@PROCID)
DECLARE @moniteur VARCHAR(128) = 'Gestionnaire Demande Reorganisation'
DECLARE @trace VARCHAR(7500)
DECLARE @local INT = 0

DECLARE @ETAT_DMD_NOUVELLE		INT = 0
DECLARE @ETAT_DMD_EN_ATTENTE	INT = 1
DECLARE @ETAT_DMD_EN_COURS		INT = 2
DECLARE @ETAT_DMD_TERMINEE		INT = 3
DECLARE @ETAT_DMD_SUSPENDUE		INT = 11
DECLARE @ETAT_DMD_ANNULEE		INT = 12

DECLARE @MIS_AFFINAGE_AUCUN		 INT = 0
DECLARE @MIS_AFFINAGE_EXECUTION	 INT = 2
DECLARE @ADR_IDSYSTEME_STKMASSE  BIGINT= 65793
DECLARE @ADR_IDBASE_STKMASSE     BIGINT= 216174985432072192
DECLARE @ADR_IDSOUSBASE_STKMASSE BIGINT= 0
		
DECLARE @dmd_nbBobines			INT = 0
DECLARE @dmd_idDemande			VARCHAR(20)
DECLARE @dmd_idSysteme_Prise	BIGINT
DECLARE @dmd_idBase_Prise		BIGINT
DECLARE @dmd_idSousBase_Prise	BIGINT
DECLARE @dmd_adresse_Prise		VARCHAR(8000)
DECLARE @mis_idMission			INT
DECLARE @dmd_idSysteme_Depose BIGINT,
		@dmd_idBase_Depose BIGINT,
		@dmd_idSousBase_Depose BIGINT
DECLARE @NbBobinesRestant INT
DECLARE @idmission INT
/*
SET @trace = 'Gestion demande'
SET @trace = @procStock + '/' + @trace
EXEC INT_ADDTRACESPECIFIQUE	@v_mon_idmoniteur = @moniteur,
							@v_log_idlog = 'DEBUG',
							@v_trace = @trace*/

-- =============================================
-- Création Mission Suite Nouvelle Demande
-- =============================================
IF EXISTS (	SELECT
				1
			FROM SPC_DMD_REORGA_STOCK_GENERAL
			WHERE SDG_ETAT = @ETAT_DMD_NOUVELLE)
BEGIN

	/*---------------------------------
		TRANSACTION
	---------------------------------*/
	IF @@TRANCOUNT > 0
	BEGIN
		SET @local = 0
	END
	ELSE
	BEGIN
  		SET @local = 1
  		BEGIN TRAN @procstock
	END
	/*-------------------------------*/
	

	DECLARE c_demande CURSOR LOCAL FAST_FORWARD FOR
		SELECT DISTINCT
			SDG_IDDEMANDE
		FROM SPC_DMD_REORGA_STOCK_GENERAL
		WHERE SDG_ETAT = @ETAT_DMD_NOUVELLE
	OPEN c_demande
	FETCH NEXT FROM c_demande INTO @dmd_idDemande
	WHILE (@@FETCH_STATUS = 0)
	BEGIN
		/*Création des missions pour les AGV*/
		SELECT
			@dmd_nbBobines = SPC_DMD_REORGA_STOCK_GENERAL.SDG_NBRESTANT,
			@dmd_idSysteme_Prise = SDG_IDSYSTEME_PRISE,
			@dmd_idBase_Prise = SDG_IDBASE_PRISE,
			@dmd_idSousBase_Prise = SDG_IDSOUSBASE_PRISE,
			@dmd_idSysteme_Depose = SPC_DMD_REORGA_STOCK_GENERAL.SDG_IDSYSTEME_DEPOSE,
			@dmd_idBase_Depose = SPC_DMD_REORGA_STOCK_GENERAL.SDG_IDBASE_DEPOSE,
			@dmd_idSousBase_Depose = SPC_DMD_REORGA_STOCK_GENERAL.SDG_IDSOUSBASE_DEPOSE
		FROM SPC_DMD_REORGA_STOCK_GENERAL
		WHERE SDG_IDDEMANDE = @dmd_idDemande
		
		WHILE( @dmd_nbBobines <> 0 )
		BEGIN
			EXEC @retour = dbo.INT_CREATEMISSIONPRISEDEPOSE	@v_mis_idmission = @mis_idMission OUTPUT,
															@v_mis_iddemande = @dmd_idDemande,
															@v_mis_priorite = 1,
															@v_tac_affinage_prise = @MIS_AFFINAGE_AUCUN,
															@v_tac_idsystemeexecution_prise = @dmd_idSysteme_Prise,
															@v_tac_idbaseexecution_prise = @dmd_idBase_Prise,
															@v_tac_idsousbaseexecution_prise = @dmd_idSousBase_Prise,
															@v_tac_affinage_depose = @MIS_AFFINAGE_EXECUTION,
															@v_tac_idsystemeexecution_depose = @dmd_idSysteme_Depose,
															@v_tac_idbaseexecution_depose = @dmd_idBase_Depose,
															@v_tac_idsousbaseexecution_depose = @dmd_idSousBase_Depose
			IF(@retour <> @CODE_OK)
			BEGIN
				SELECT
					@dmd_adresse_Prise = dbo.INT_ADRESSE.ADR_ADRESSE
				FROM dbo.INT_ADRESSE
				WHERE dbo.INT_ADRESSE.ADR_IDSYSTEME = @dmd_idSysteme_Prise
				AND dbo.INT_ADRESSE.ADR_IDBASE = @dmd_idBase_Prise
				AND dbo.INT_ADRESSE.ADR_IDSOUSBASE = @dmd_idSousBase_Prise

				SET @trace = 'INT_CREATEMISSIONPRISEDEPOSE : ' + ISNULL(CONVERT(VARCHAR, @retour), 'NULL')
							+ ', @v_mis_iddemande = ' + ISNULL(CONVERT(VARCHAR, @dmd_idDemande), 'NULL')
							+ ', @v_mis_priorite = ' + ISNULL(CONVERT(VARCHAR, 1), 'NULL')
							+ ', @v_tac_affinage_prise = ' + ISNULL(CONVERT(VARCHAR, @MIS_AFFINAGE_AUCUN), 'NULL')
							+ ', @v_tac_idsystemeexecution_prise = ' + ISNULL(CONVERT(VARCHAR, @dmd_idSysteme_Prise), 'NULL')
							+ ', @v_tac_idbaseexecution_prise = ' + ISNULL(CONVERT(VARCHAR, @dmd_idBase_Prise), 'NULL')
							+ ', @v_tac_idsousbaseexecution_prise = ' + ISNULL(CONVERT(VARCHAR, @dmd_idSousBase_Prise), 'NULL')
							+ ', @dmd_adresse_Prise = ' + ISNULL(CONVERT(VARCHAR, @dmd_adresse_Prise), 'NULL')
							+ ', @v_tac_affinage_depose = ' + ISNULL(CONVERT(VARCHAR, @MIS_AFFINAGE_EXECUTION), 'NULL')
							+ ', @v_tac_idsystemeexecution_depose = ' + ISNULL(CONVERT(VARCHAR, @ADR_IDSYSTEME_STKMASSE), 'NULL')
							+ ', @v_tac_idbaseexecution_depose = ' + ISNULL(CONVERT(VARCHAR, @ADR_IDBASE_STKMASSE), 'NULL')
							+ ', @v_tac_idsousbaseexecution_depose = ' + ISNULL(CONVERT(VARCHAR, @ADR_IDSOUSBASE_STKMASSE), 'NULL')
				SET @trace = @procStock + '/' + @trace
				EXEC INT_ADDTRACESPECIFIQUE	@v_mon_idmoniteur = @moniteur,
											@v_log_idlog = 'ERREUR',
											@v_trace = @trace
				
				-- Changement d'état
				EXEC @retour = SPC_DDG_MODIFIER_DEMANDE	@v_idDemande = @dmd_idDemande,
														@v_etat = @ETAT_DMD_ANNULEE
				
				IF( @retour <> @CODE_OK )
				BEGIN
					SET @trace = 'SPC_DDG_MODIFIER_DEMANDE : ' + ISNULL(CONVERT(VARCHAR, @retour), 'NULL')
							+ ', @v_idDemande = ' + ISNULL(CONVERT(VARCHAR, @dmd_idDemande), 'NULL')
							+ ', @v_etat = ' + ISNULL(CONVERT(VARCHAR, @ETAT_DMD_ANNULEE), 'NULL')
					SET @trace = @procStock + '/' + @trace
					EXEC INT_ADDTRACESPECIFIQUE	@v_mon_idmoniteur = @moniteur,
												@v_log_idlog = 'ERREUR',
												@v_trace = @trace
					BREAK
				END
				
				BREAK
			END
			SET @dmd_nbBobines -= 1
		END

		/*Modification de la demande en état en attente*/
		EXEC @retour = SPC_DDG_MODIFIER_DEMANDE	@v_idDemande = @dmd_idDemande,
												@v_etat = @ETAT_DMD_EN_ATTENTE

		IF(@retour <> @CODE_OK)
		BEGIN
			SET @trace = 'SPC_DDG_MODIFIER_DEMANDE : ' + ISNULL(CONVERT(VARCHAR, @retour), 'NULL')
							+ ', @v_idDemande = ' + ISNULL(CONVERT(VARCHAR, @dmd_idDemande), 'NULL')
							+ ', @v_etat = ' + ISNULL(CONVERT(VARCHAR, @ETAT_DMD_ANNULEE), 'NULL')
			SET @trace = @procStock + '/' + @trace
			EXEC INT_ADDTRACESPECIFIQUE	@v_mon_idmoniteur = @moniteur,
										@v_log_idlog = 'ERREUR',
										@v_trace = @trace
			BREAK
		END

		FETCH NEXT FROM c_demande INTO @dmd_idDemande
	END
	CLOSE c_demande
	DEALLOCATE c_demande

	/*---------------------------------
		TRANSACTION
	---------------------------------*/
	IF( @local = 1 )
	BEGIN
		IF(@retour <> @CODE_OK)
		BEGIN
			ROLLBACK TRAN @procStock
		END
		ELSE
		BEGIN
			COMMIT TRAN @procStock
		END
	END
	/*-------------------------------*/	

END


-- =============================================
-- Réalisation d'une demande
-- =============================================
IF EXISTS (	SELECT
				1
			FROM SPC_DMD_REORGA_STOCK_GENERAL
			WHERE SDG_ETAT IN (@ETAT_DMD_EN_COURS))
BEGIN
	/*---------------------------------
		TRANSACTION
	---------------------------------*/
	IF @@TRANCOUNT > 0
	BEGIN
		SET @local = 0
	END
	ELSE
	BEGIN
  		SET @local = 1
  		BEGIN TRAN @procstock
	END
	/*-------------------------------*/

	DECLARE c_demande CURSOR LOCAL FAST_FORWARD FOR
		SELECT DISTINCT
			SDG_IDDEMANDE
		FROM SPC_DMD_REORGA_STOCK_GENERAL
		WHERE SDG_ETAT in (@ETAT_DMD_EN_COURS)
	OPEN c_demande
	FETCH NEXT FROM c_demande INTO @dmd_idDemande
	WHILE (@@FETCH_STATUS = 0)
	BEGIN
		IF EXISTS (SELECT 1 from SPC_DMD_REORGA_STOCK_GENERAL where SPC_DMD_REORGA_STOCK_GENERAL.SDG_IDDEMANDE = @dmd_idDemande 
																	and SPC_DMD_REORGA_STOCK_GENERAL.SDG_NBRESTANT = 0)
			EXEC @retour = SPC_DDG_MODIFIER_DEMANDE	@v_idDemande = @dmd_idDemande,	@v_etat = @ETAT_DMD_TERMINEE

		SET @retour = @@ERROR
		
		IF(@retour <> @CODE_OK)
		BEGIN
			SET @trace = 'DELETE SPC_DMD_REORGASTOCK : ' + ISNULL(CONVERT(VARCHAR, @retour), 'NULL')
			SET @trace = @procStock + '/' + @trace
			EXEC INT_ADDTRACESPECIFIQUE	@v_mon_idmoniteur = @moniteur,
										@v_log_idlog = 'ERREUR',
										@v_trace = @trace
			
			BREAK
		END

		FETCH NEXT FROM c_demande INTO @dmd_idDemande
	END
	CLOSE c_demande
	DEALLOCATE c_demande

	/*---------------------------------
		TRANSACTION
	---------------------------------*/
	IF( @local = 1 )
	BEGIN
		IF(@retour <> @CODE_OK)
		BEGIN
			ROLLBACK TRAN @procStock
		END
		ELSE
		BEGIN
			COMMIT TRAN @procStock
		END
	END
	/*-------------------------------*/

END

-- =============================================
-- Suspension Demande
-- =============================================
IF EXISTS (	SELECT
				1
			FROM SPC_DMD_REORGA_STOCK_GENERAL
			WHERE SDG_ETAT IN (@ETAT_DMD_SUSPENDUE))
BEGIN
	/*---------------------------------
		TRANSACTION
	---------------------------------*/
	IF @@TRANCOUNT > 0
	BEGIN
		SET @local = 0
	END
	ELSE
	BEGIN
  		SET @local = 1
  		BEGIN TRAN @procstock
	END
	/*-------------------------------*/
	DECLARE c_demande CURSOR LOCAL FAST_FORWARD FOR
		SELECT DISTINCT
			SDG_IDDEMANDE
		FROM SPC_DMD_REORGA_STOCK_GENERAL
		WHERE SDG_ETAT in (@ETAT_DMD_SUSPENDUE)
	OPEN c_demande
	FETCH NEXT FROM c_demande INTO @dmd_idDemande
	WHILE (@@FETCH_STATUS = 0)
	BEGIN
		--Annulation des missions associées et pas en cours
		DECLARE c_mission CURSOR LOCAL FAST_FORWARD FOR
			SELECT DISTINCT
				INT_MISSION_VIVANTE.MIS_IDMISSION
			FROM INT_MISSION_VIVANTE
			WHERE MIS_DEMANDE = @dmd_idDemande
			AND INT_MISSION_VIVANTE.MIS_IDETATMISSION NOT IN (2)
		OPEN c_mission
		FETCH NEXT FROM c_mission INTO @idmission
		WHILE (@@FETCH_STATUS = 0)
		BEGIN
			EXEC INT_CANCELMISSION @idmission
			FETCH NEXT FROM c_mission INTO @idmission
		END
		CLOSE c_mission
		DEALLOCATE c_mission

		SET @retour = @@ERROR
		
		IF(@retour <> @CODE_OK)
		BEGIN
			SET @trace = 'SUSPENSION SPC_DMD_REORGASTOCK : ' + ISNULL(CONVERT(VARCHAR, @retour), 'NULL')
			SET @trace = @procStock + '/' + @trace
			EXEC INT_ADDTRACESPECIFIQUE	@v_mon_idmoniteur = @moniteur,
										@v_log_idlog = 'ERREUR',
										@v_trace = @trace
			
			BREAK
		END

		FETCH NEXT FROM c_demande INTO @dmd_idDemande
	END
	CLOSE c_demande
	DEALLOCATE c_demande

	/*---------------------------------
		TRANSACTION
	---------------------------------*/
	IF( @local = 1 )
	BEGIN
		IF(@retour <> @CODE_OK)
		BEGIN
			ROLLBACK TRAN @procStock
		END
		ELSE
		BEGIN
			COMMIT TRAN @procStock
		END
	END
	/*-------------------------------*/

END

-- =============================================
-- Suppression Demande
-- =============================================
IF EXISTS (	SELECT
				1
			FROM SPC_DMD_REORGA_STOCK_GENERAL
			WHERE SDG_ETAT IN (@ETAT_DMD_TERMINEE, @ETAT_DMD_ANNULEE))
BEGIN
	/*---------------------------------
		TRANSACTION
	---------------------------------*/
	IF @@TRANCOUNT > 0
	BEGIN
		SET @local = 0
	END
	ELSE
	BEGIN
  		SET @local = 1
  		BEGIN TRAN @procstock
	END
	/*-------------------------------*/
	

	DECLARE c_demande CURSOR LOCAL FAST_FORWARD FOR
		SELECT DISTINCT
			SDG_IDDEMANDE
		FROM SPC_DMD_REORGA_STOCK_GENERAL
		WHERE SDG_ETAT in (@ETAT_DMD_TERMINEE, @ETAT_DMD_ANNULEE)
	OPEN c_demande
	FETCH NEXT FROM c_demande INTO @dmd_idDemande
	WHILE (@@FETCH_STATUS = 0)
	BEGIN
		--Annulation des missions associées et pas en cours
		DECLARE c_mission CURSOR LOCAL FAST_FORWARD FOR
			SELECT DISTINCT
				INT_MISSION_VIVANTE.MIS_IDMISSION
			FROM INT_MISSION_VIVANTE
			WHERE MIS_DEMANDE = @dmd_idDemande
			AND INT_MISSION_VIVANTE.MIS_IDETATMISSION NOT IN (2)
		OPEN c_mission
		FETCH NEXT FROM c_mission INTO @idmission
		WHILE (@@FETCH_STATUS = 0)
		BEGIN
			EXEC INT_CANCELMISSION @idmission
			FETCH NEXT FROM c_mission INTO @idmission
		END
		CLOSE c_mission
		DEALLOCATE c_mission		
		
		DELETE from SPC_DMD_REORGA_STOCK_GENERAL where SDG_IDDEMANDE = @dmd_idDemande

		SET @retour = @@ERROR
		
		IF(@retour <> @CODE_OK)
		BEGIN
			SET @trace = 'DELETE SPC_DMD_REORGASTOCK : ' + ISNULL(CONVERT(VARCHAR, @retour), 'NULL')
			SET @trace = @procStock + '/' + @trace
			EXEC INT_ADDTRACESPECIFIQUE	@v_mon_idmoniteur = @moniteur,
										@v_log_idlog = 'ERREUR',
										@v_trace = @trace
			
			BREAK
		END

		FETCH NEXT FROM c_demande INTO @dmd_idDemande
	END
	CLOSE c_demande
	DEALLOCATE c_demande

	/*---------------------------------
		TRANSACTION
	---------------------------------*/
	IF( @local = 1 )
	BEGIN
		IF(@retour <> @CODE_OK)
		BEGIN
			ROLLBACK TRAN @procStock
		END
		ELSE
		BEGIN
			COMMIT TRAN @procStock
		END
	END
	/*-------------------------------*/

END


END
