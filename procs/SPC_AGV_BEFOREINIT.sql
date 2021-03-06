SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
-- =============================================
-- Description:	Gestion Before Init AGV
-- =============================================
CREATE PROCEDURE [dbo].[SPC_AGV_BEFOREINIT]
	 @v_iag_idagv tinyint,
	 @v_iag_charge bit
AS	 
BEGIN
-- Déclaration des constantes
DECLARE @ADRSYS_HORS_SYSTEME BIGINT,
		@ADRBASE_HORS_SYSTEME BIGINT,
		@ADRSOUSBASE_HORS_SYSTEME BIGINT
DECLARE @TYPE_GFS TINYINT,
		@TYPE_GBH TINYINT	
DECLARE @AGV_CHARGE TINYINT,
		@AGV_VIDE TINYINT
DECLARE @VAR_DMDAUTORISATION_RECEP INT,
		@VAR_DMDAUTORISATION_ENT_DEMAC Int
Declare @CODE_OK Int,
		@ETATDMD_SUSPENDUE TinyInt	

-- Déclaration des variables
DECLARE @IdMission INT,
		@TypeAGV TINYINT,
		@ChaineTrace VARCHAR(200),
		@Retour Int,
		@IdBobine Int,
		@IdDemande Int,
		@CategorieDmd Int

-- Initialisation des constantes
SET @ADRSYS_HORS_SYSTEME  = 65793
SET @ADRBASE_HORS_SYSTEME = 144224044022038785
SET @ADRSOUSBASE_HORS_SYSTEME = 65793

SET @AGV_VIDE	= 0
SET @AGV_CHARGE = 1

SET @VAR_DMDAUTORISATION_RECEP = 1103
Set @VAR_DMDAUTORISATION_ENT_DEMAC = 2101

Set @CODE_OK = 0
Set @ETATDMD_SUSPENDUE = 4


-- Initialisation des variables
Set @Retour = @CODE_OK

	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

-- Recherche du type AGV
SELECT @TypeAGV = IAG_IDTYPEAGV FROM INT_AGV 
	WHERE IAG_IDAGV = @v_iag_idagv

SET @ChaineTrace = '@TypeAGV='+CONVERT (varchar,@TypeAGV) + ',EtatAgv='+CONVERT(varchar,@v_iag_charge)
EXEC INT_ADDTRACESPECIFIQUE '[SPC_AGV_BEFOREINIT]', '[DBGAGV]', @ChaineTrace

-- Init a vide
------------------------------------
IF @v_iag_charge = @AGV_VIDE
BEGIN
	SELECT @IdMission = MIS_IDMISSION, @IdBobine = MIS_IDCHARGE 
		FROM INT_MISSION_VIVANTE WHERE MIS_IDAGV = @v_iag_idagv

	-- Exécution Manuelle de la mission pour dépose bobine Hors Système	
	IF @@ROWCOUNT > 0
	Begin
		Exec INT_SETVERIFICATIONADRESSE @ADRSYS_HORS_SYSTEME, @ADRBASE_HORS_SYSTEME, @ADRSOUSBASE_HORS_SYSTEME, 0
		EXEC @Retour = INT_EXECUTEMANUELLEMISSION @IdMission, @ADRSYS_HORS_SYSTEME,
										@ADRBASE_HORS_SYSTEME, @ADRSOUSBASE_HORS_SYSTEME
	End
										
	SET @ChaineTrace = '@@IdMission='+CONVERT (varchar,@IdMission) + ',@Retour='+CONVERT(varchar,@Retour)
	EXEC INT_ADDTRACESPECIFIQUE '[SPC_AGV_BEFOREINIT]', '[DBGAGV]', @ChaineTrace
END

Return @Retour

END

