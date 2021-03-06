SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
-- =============================================
-- Description:	Gestion des demandes
-- =============================================
CREATE PROCEDURE [dbo].[SPC_DDD_GESTION]
AS
BEGIN

declare @CODE_OK int = 0
declare	@CODE_KO int = 1

set @CODE_OK = 0
set @CODE_KO = 1

DECLARE @retour INT = @CODE_OK
DECLARE @procStock VARCHAR(128) = OBJECT_NAME(@@PROCID)
DECLARE @moniteur VARCHAR(128) = 'Gestionnaire Demande Démaculeuse'
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
DECLARE @ADR_IDSYSTEME_DEMAC  BIGINT= 65793
DECLARE @ADR_IDBASE_DEMAC_5     BIGINT= 144118490906034433
DECLARE @ADR_IDBASE_DEMAC_6     BIGINT= 144118490906099970
DECLARE @ADR_IDSOUSBASE_DEMAC  BIGINT= 65793

DECLARE @dmd_idDemande			VARCHAR(20)
DECLARE @dmd_idSysteme_Prise	BIGINT
DECLARE @dmd_idBase_Prise		BIGINT
DECLARE @dmd_idSousBase_Prise	BIGINT
DECLARE @dmd_adresse_Prise		VARCHAR(8000)
DECLARE @mis_idMission			INT
DECLARE @dmd_idSysteme_Depose BIGINT,
		@dmd_idBase_Depose BIGINT,
		@dmd_idSousBase_Depose BIGINT
DECLARE @dmd_Rotative INT
DECLARE @dmd_Laize INT
DECLARE @dmd_Diametre INT
DECLARE @dmd_Grammage INT
DECLARE @dmd_IdFournisseur INT
DECLARE @IdCharge INT

-- =============================================
-- Création Mission Suite Nouvelle Demande
-- =============================================
IF EXISTS (	SELECT
				1
			FROM SPC_DMD_APPRO_DEMAC
			WHERE SDD_ETAT = @ETAT_DMD_NOUVELLE)
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
			SDD_IDDEMANDE
		FROM SPC_DMD_APPRO_DEMAC
		WHERE SDD_ETAT = @ETAT_DMD_NOUVELLE
	OPEN c_demande
	FETCH NEXT FROM c_demande INTO @dmd_idDemande
	WHILE (@@FETCH_STATUS = 0)
	BEGIN
		/*Création de la mission*/

		-- Récuperation des infos de la demande
		Select @dmd_Rotative = SPC_DMD_APPRO_DEMAC.SDD_ROTATIVE,
				@dmd_Laize = SPC_DMD_APPRO_DEMAC.SDD_LAIZE,
				@dmd_Diametre = SPC_DMD_APPRO_DEMAC.SDD_DIAMETRE,
				@dmd_Grammage = SPC_DMD_APPRO_DEMAC.SDD_GRAMMAGE,
				@dmd_IdFournisseur = SPC_DMD_APPRO_DEMAC.SDD_IDFOURNISSEUR
		from SPC_DMD_APPRO_DEMAC
		Where SDD_IDDEMANDE = @dmd_idDemande
		
		-- Allée de prise
		SELECT 
			@dmd_idSysteme_Prise = SAG_IDSYSTEME,
			@dmd_idBase_Prise = SAG_IDBASE,
			@dmd_idSousBase_Prise = SAG_IDSOUSBASE
		from SPC_ADRESSE_STOCK_GENERAL
		inner join INT_CHARGE_VIVANTE on INT_CHARGE_VIVANTE.CHG_IDSYSTEME = SPC_ADRESSE_STOCK_GENERAL.SAG_IDSYSTEME
										AND INT_CHARGE_VIVANTE.CHG_IDBASE = SPC_ADRESSE_STOCK_GENERAL.SAG_IDBASE
										AND INT_CHARGE_VIVANTE.CHG_IDSOUSBASE = SPC_ADRESSE_STOCK_GENERAL.SAG_IDSOUSBASE
		inner join SPC_CHARGE_BOBINE on INT_CHARGE_VIVANTE.CHG_IDCHARGE= SPC_CHARGE_BOBINE.SCB_IDCHARGE
		where SPC_CHARGE_BOBINE.SCB_LAIZE = @dmd_Laize
			AND SPC_CHARGE_BOBINE.SCB_DIAMETRE = @dmd_Diametre
			AND SPC_CHARGE_BOBINE.SCB_GRAMMAGE = @dmd_Grammage
			AND SPC_CHARGE_BOBINE.SCB_IDFOURNISSEUR = @dmd_IdFournisseur
		
		-- Démaculeuse de dépose
		IF @dmd_Rotative in (5,6)
		BEGIN
			IF @dmd_Rotative = 5
				SET @dmd_idBase_Depose = @ADR_IDBASE_DEMAC_5
			ELSE IF @dmd_Rotative = 6
				SET @dmd_idBase_Depose = @ADR_IDBASE_DEMAC_6
		
			SET @dmd_idSysteme_Depose = @ADR_IDSYSTEME_DEMAC
			SET @dmd_idSousBase_Depose = @ADR_IDSOUSBASE_DEMAC
		END
		ELSE
		BEGIN
			SET @trace = ' : Mauvaise information de rotative, @v_idDemande = ' + ISNULL(CONVERT(VARCHAR, @dmd_Rotative), 'NULL')
					SET @trace = @procStock + '/' + @trace
					EXEC INT_ADDTRACESPECIFIQUE	@v_mon_idmoniteur = @moniteur,
												@v_log_idlog = 'ERREUR',
												@v_trace = @trace
		END

		-- Recherche de la charge
		IF @dmd_idBase_Prise > 0
			EXEC @IdCharge = dbo.INT_GETCHARGE @dmd_idSysteme_Prise, @dmd_idBase_Prise, @dmd_idSousBase_Prise, NULL
		ELSE
		BEGIN
			SET @trace = ' : Allée non trouvée, @v_idDemande = ' + ISNULL(CONVERT(VARCHAR, @dmd_idDemande), 'NULL')
					SET @trace = @procStock + '/' + @trace
					EXEC INT_ADDTRACESPECIFIQUE	@v_mon_idmoniteur = @moniteur,
												@v_log_idlog = 'DEBUG',
												@v_trace = @trace

		END
		

		IF @IdCharge > 0
		BEGIN
			-- Tout est OK, on créé la mission
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
							+ ', @v_tac_idsystemeexecution_depose = ' + ISNULL(CONVERT(VARCHAR, @dmd_idSysteme_Depose), 'NULL')
							+ ', @v_tac_idbaseexecution_depose = ' + ISNULL(CONVERT(VARCHAR, @dmd_idBase_Depose), 'NULL')
							+ ', @v_tac_idsousbaseexecution_depose = ' + ISNULL(CONVERT(VARCHAR, @dmd_idSousBase_Depose), 'NULL')
				SET @trace = @procStock + '/' + @trace
				EXEC INT_ADDTRACESPECIFIQUE	@v_mon_idmoniteur = @moniteur,
											@v_log_idlog = 'ERREUR',
											@v_trace = @trace
			
				-- Changement d'état si la mission n'a pas pu être créée
				EXEC @retour = SPC_DDD_MODIFIER_DEMANDE	@v_idDemande = @dmd_idDemande,
														@v_etat = @ETAT_DMD_ANNULEE
				
				IF( @retour <> @CODE_OK )
				BEGIN
					SET @trace = 'SPC_DDD_MODIFIER_DEMANDE : ' + ISNULL(CONVERT(VARCHAR, @retour), 'NULL')
							+ ', @v_idDemande = ' + ISNULL(CONVERT(VARCHAR, @dmd_idDemande), 'NULL')
							+ ', @v_etat = ' + ISNULL(CONVERT(VARCHAR, @ETAT_DMD_ANNULEE), 'NULL')
					SET @trace = @procStock + '/' + @trace
					EXEC INT_ADDTRACESPECIFIQUE	@v_mon_idmoniteur = @moniteur,
												@v_log_idlog = 'ERREUR',
												@v_trace = @trace
					BREAK
				END
			END
			ELSE
			BEGIN
				-- Changement d'état suite à création mission
				EXEC @retour = SPC_DDD_MODIFIER_DEMANDE	@v_idDemande = @dmd_idDemande,
														@v_etat = @ETAT_DMD_EN_ATTENTE
				IF( @retour <> @CODE_OK )
				BEGIN
					SET @trace = 'SPC_DDD_MODIFIER_DEMANDE : ' + ISNULL(CONVERT(VARCHAR, @retour), 'NULL')
							+ ', @v_idDemande = ' + ISNULL(CONVERT(VARCHAR, @dmd_idDemande), 'NULL')
							+ ', @v_etat = ' + ISNULL(CONVERT(VARCHAR, @ETAT_DMD_ANNULEE), 'NULL')
					SET @trace = @procStock + '/' + @trace
					EXEC INT_ADDTRACESPECIFIQUE	@v_mon_idmoniteur = @moniteur,
												@v_log_idlog = 'ERREUR',
												@v_trace = @trace
					BREAK
				END
			END
		END
		ELSE
		BEGIN
			SET @trace = ' : Pas de charge trouvée, @v_idDemande = ' + ISNULL(CONVERT(VARCHAR, @dmd_idDemande), 'NULL')
					SET @trace = @procStock + '/' + @trace
					EXEC INT_ADDTRACESPECIFIQUE	@v_mon_idmoniteur = @moniteur,
												@v_log_idlog = 'ERREUR',
												@v_trace = @trace
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
-- Suppression des demandes
-- =============================================
IF EXISTS (	SELECT
				1
			FROM SPC_DMD_APPRO_DEMAC
			WHERE SDD_ETAT IN (@ETAT_DMD_TERMINEE, @ETAT_DMD_ANNULEE))
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
			SDD_IDDEMANDE
		FROM SPC_DMD_APPRO_DEMAC
		WHERE SDD_ETAT in (@ETAT_DMD_TERMINEE, @ETAT_DMD_ANNULEE)
	OPEN c_demande
	FETCH NEXT FROM c_demande INTO @dmd_idDemande
	WHILE (@@FETCH_STATUS = 0)
	BEGIN
		DELETE from SPC_DMD_APPRO_DEMAC where SPC_DMD_APPRO_DEMAC.SDD_IDDEMANDE = @dmd_idDemande

		SET @retour = @@ERROR
		
		IF(@retour <> @CODE_OK)
		BEGIN
			SET @trace =' Suppression des demandes: @retour ' + ISNULL(CONVERT(VARCHAR, @retour), 'NULL')
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
