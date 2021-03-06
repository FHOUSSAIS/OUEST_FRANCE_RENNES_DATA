SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
-- =============================================
-- Description:	Modification du Nombre de Bobines Maximal en Hauteur
-- =============================================
CREATE PROCEDURE [dbo].[SPC_DSG_IHM_SETNBBOBINEHAUTEUR]
	@v_idSysteme  bigint,
	@v_idBase     bigint,
	@v_idSousBase bigint,
	@v_typeLaize  int,
	@v_nbBobine   int
AS
BEGIN

declare @CODE_OK int,
		@CODE_KO int
DECLARE @CODE_KO_ALLEE_MISSIONENCOURS SMALLINT,
		@CODE_KO_ALLEE_NONVIDE SMALLINT,
		@ETATTAC_ENATTENTE TINYINT,
		@ETATTAC_ENCOURS TINYINT

declare @retour      int,
		@local       int,
		@procStock   varchar(128),
		@trace varchar(7500)
declare @lze_champ   varchar(100),
		@sql_cmde    varchar(max),
		@StockBImpair bit

set @CODE_OK = 0
set @CODE_KO = 1
SET @ETATTAC_ENATTENTE = 1
SET @ETATTAC_ENCOURS = 2
SET @CODE_KO_ALLEE_MISSIONENCOURS = -1400
SET @CODE_KO_ALLEE_NONVIDE = -1399

set @retour = @CODE_OK
set @procStock = OBJECT_NAME(@@PROCID)
DECLARE @moniteur VARCHAR(128) = 'Gestionnaire De Stock General'


SET @trace = '@v_AdrBase = ' + ISNULL(CONVERT(VARCHAR, @v_idBase), 'NULL')
		+', @v_typeLaize = ' + ISNULL(CONVERT(VARCHAR, @v_typeLaize), 'NULL')
		+', @v_nbBobine = ' + ISNULL(CONVERT(VARCHAR, @v_nbBobine), 'NULL')
SET @trace = @procStock + '/' + @trace
EXEC INT_ADDTRACESPECIFIQUE	@v_mon_idmoniteur = @moniteur,
							@v_log_idlog = 'DEBUG',
							@v_trace = @trace

	SELECT @v_typeLaize = SPC_CHG_LAIZE.SCL_TYPE_LAIZE from SPC_CHG_LAIZE where SPC_CHG_LAIZE.SCL_LAIZE = @v_typeLaize

	-- Vérification Allée Vide
	if exists( select 1 from INT_CHARGE_VIVANTE where CHG_IDSYSTEME = @v_idSysteme and CHG_IDBASE = @v_idBase and CHG_IDSOUSBASE = @v_idSousBase )
	begin
		return @CODE_KO_ALLEE_NONVIDE -- Allée Non Vide
	end
	
	-- Vérification des interdictions : l'allée ne doit pas être contenu dans une mission
	IF @retour = @CODE_OK
	BEGIN
		IF EXISTS (SELECT 1 FROM INT_TACHE_MISSION
					WHERE TAC_IDSYSTEMEEXECUTION = @v_idSysteme AND TAC_IDBASEEXECUTION = @v_idBase AND TAC_IDSOUSBASEEXECUTION = @v_idSousBase
							AND ((TAC_IDACTION = 4 AND TAC_IDETATTACHE IN (@ETATTAC_ENATTENTE, @ETATTAC_ENCOURS))
								 OR (TAC_IDACTION = 2 AND TAC_IDETATTACHE = @ETATTAC_ENCOURS)))
			return @CODE_KO_ALLEE_MISSIONENCOURS
	END	

	-- Paramétrage déjà existant -> On met à jour
	-- Sinon on insert dans la table
	IF EXISTS (SELECT 1 from SPC_STK_NBLAIZEHAUTEUR 
					where SPC_STK_NBLAIZEHAUTEUR.NLH_IDSYSTEME = @v_idSysteme
							and SPC_STK_NBLAIZEHAUTEUR.NLH_IDBASE = @v_idBase
							and SPC_STK_NBLAIZEHAUTEUR.NLH_IDSOUSBASE = @v_idSousBase
							and SPC_STK_NBLAIZEHAUTEUR.NLH_TYPELAIZE = @v_typeLaize)
	BEGIN
		-- Si le paramètre = 0 => Suppression de la contrainte
		IF @v_nbBobine = 0
		BEGIN
			DELETE from SPC_STK_NBLAIZEHAUTEUR 
				where SPC_STK_NBLAIZEHAUTEUR.NLH_IDSYSTEME = @v_idSysteme
					and SPC_STK_NBLAIZEHAUTEUR.NLH_IDBASE = @v_idBase
					and SPC_STK_NBLAIZEHAUTEUR.NLH_IDSOUSBASE = @v_idSousBase
					and SPC_STK_NBLAIZEHAUTEUR.NLH_TYPELAIZE = @v_typeLaize
		END
		ELSE
		BEGIN
			UPDATE SPC_STK_NBLAIZEHAUTEUR 
			SET NLH_NBBOBINES = @v_nbBobine
				where SPC_STK_NBLAIZEHAUTEUR.NLH_IDSYSTEME = @v_idSysteme
					and SPC_STK_NBLAIZEHAUTEUR.NLH_IDBASE = @v_idBase
					and SPC_STK_NBLAIZEHAUTEUR.NLH_IDSOUSBASE = @v_idSousBase
					and SPC_STK_NBLAIZEHAUTEUR.NLH_TYPELAIZE = @v_typeLaize
		END
	END
	ELSE
	BEGIN
			INSERT INTO SPC_STK_NBLAIZEHAUTEUR 
					(SPC_STK_NBLAIZEHAUTEUR.NLH_IDSYSTEME
					,SPC_STK_NBLAIZEHAUTEUR.NLH_IDBASE
					,SPC_STK_NBLAIZEHAUTEUR.NLH_IDSOUSBASE
					,SPC_STK_NBLAIZEHAUTEUR.NLH_TYPELAIZE
					,SPC_STK_NBLAIZEHAUTEUR.NLH_NBBOBINES)
				VALUES
					(@v_idSysteme
					,@v_idBase
					,@v_idSousBase
					,@v_typeLaize
					,@v_nbBobine)
	END
	
	set @retour = @@ERROR
	if( @retour <> @CODE_OK )
	begin
		set @trace = 'Update NB LAIZE HAUTEUR' + CONVERT( varchar, ISNULL( @retour, -1 ) )
		exec INT_ADDTRACESPECIFIQUE @procStock, 'ERREUR', @trace
		set @retour = -1549 -- Erreur Interne
	end

	-- Ajout d'une trace de suivi
	IF @retour = @CODE_OK
	BEGIN
		SET @trace = 'Modification NbMaxBobines/Hauteur ('+convert(varchar,@v_nbBobine)
					+'), Laize ('+convert(varchar,(SELECT SCL_SYMBOLE FROM SPC_CHG_LAIZE WHERE SCL_LAIZE=@v_typeLaize))
					+'), Allée '+ (SELECT ADr_ADRESSE FROM INT_ADRESSE WHERE ADR_IDSYSTEME=@v_idSysteme AND ADR_IDBASE=@v_idBase AND ADR_IDSOUSBASE=@v_idSousBase)
		EXEC INT_ADDTRACESPECIFIQUE '[IHM]', '[TRCSTK]', @trace
	END

	return @retour
	
END

