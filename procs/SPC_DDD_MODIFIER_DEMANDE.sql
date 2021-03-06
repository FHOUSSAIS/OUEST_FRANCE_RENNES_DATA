SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
-- =============================================
-- Description:	Modifier les Demandes de la démac
-- @v_idDemande	: Id de demande 
-- @v_etat		: Etat de la demande
-- @v_priorite	: Priorité
-- =============================================
CREATE PROCEDURE [dbo].[SPC_DDD_MODIFIER_DEMANDE]
	@v_idDemande	VARCHAR(20),
	@v_etat			int = NULL,
	@v_priorite		int = NULL,
	@v_idBobine		int = NULL
AS
BEGIN

declare @CODE_OK int,
		@CODE_KO int
		
declare @retour      int
DECLARE @procStock VARCHAR(128) = OBJECT_NAME(@@PROCID)
DECLARE @moniteur VARCHAR(128) = 'Gestionnaire Demande Appro Demac'
DECLARE @trace VARCHAR(7500)

set @CODE_OK = 0
set @CODE_KO = 1

set @retour = @CODE_OK

	DECLARE @libelleEtat VARCHAR(8000) = (SELECT dbo.INT_GETLIBELLE(dbo.SPC_DMD_ETAT.SDE_IDTRADUCTION, 'fra') FROM dbo.SPC_DMD_ETAT WHERE dbo.SPC_DMD_ETAT.SDE_IDETAT = @v_etat)
	
	-- Vérifcation Existance Demande
	IF NOT EXISTS(SELECT 1 FROM dbo.SPC_DMD_APPRO_DEMAC WHERE dbo.SPC_DMD_APPRO_DEMAC.SDD_IDDEMANDE = @v_idDemande)
	BEGIN
		SET @trace = 'Modifier Demande, la demande n existe pas : ' + ISNULL(CONVERT(VARCHAR, @v_idDemande), 'NULL')
		SET @trace = @procStock + '/' + @trace
		EXEC INT_ADDTRACESPECIFIQUE	@v_mon_idmoniteur = @moniteur,
									@v_log_idlog = 'ERREUR',
									@v_trace = @trace
		SET @retour = @CODE_KO
	END
	
	IF (@retour = @CODE_OK) 
	BEGIN
		UPDATE SPC_DMD_APPRO_DEMAC set 
			SDD_ETAT = ISNULL(@v_etat,SDD_ETAT),
			SDD_PRIORITE = ISNULL(@v_priorite,SDD_PRIORITE),
			SDD_IDBOBINE = ISNULL(@v_idBobine,SDD_IDBOBINE)
			where SDD_IDDEMANDE = @v_idDemande
	END
	-- tester le code erreur est inutile car pas de try/catch
	SET @retour = @@ERROR
	
	if( @retour = @CODE_OK )
	begin
		SET @trace = 'la demande a été mise à jour ' + ISNULL(CONVERT(VARCHAR, @retour), 'NULL')
			+ ', @v_idDemande = ' + ISNULL(CONVERT(VARCHAR, @v_idDemande), 'NULL')	
			+ ', @v_etat = ' + ISNULL(CONVERT(VARCHAR, @v_etat), 'NULL')
			+ ', @libelleEtat = ' + ISNULL(CONVERT(VARCHAR, @libelleEtat), 'NULL')
			+ ', @v_idBobine = ' + ISNULL(CONVERT(VARCHAR, @v_idBobine), 'NULL')
		SET @trace = @procStock + '/' + @trace
		EXEC INT_ADDTRACESPECIFIQUE	@v_mon_idmoniteur = @moniteur,
								@v_log_idlog = 'DEBUG',
								@v_trace = @trace
		EXEC SPC_DDD_INSERER_TRACE @v_idDemande = @v_idDemande
	end

	if( @retour <> @CODE_OK )
	begin
		SET @trace = 'Erreur a la mise a jour de la demande ' + ISNULL(CONVERT(VARCHAR, @retour), 'NULL')
				+ ', @v_idDemande = ' + ISNULL(CONVERT(VARCHAR, @v_idDemande), 'NULL')	
				+ ', @v_etat = ' + ISNULL(CONVERT(VARCHAR, @v_etat), 'NULL')
				+ ', @libelleEtat = ' + ISNULL(CONVERT(VARCHAR, @libelleEtat), 'NULL')
		SET @trace = @procStock + '/' + @trace
		EXEC INT_ADDTRACESPECIFIQUE	@v_mon_idmoniteur = @moniteur,
									@v_log_idlog = 'ERREUR',
									@v_trace = @trace
	end

	return @retour
END

