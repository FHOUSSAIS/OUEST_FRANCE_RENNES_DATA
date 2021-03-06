SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
-- =============================================
-- Description:	Création d'une bobine
	-- @v_idcharge			: identifiant bobine
	-- @v_poids				: Poids de la bobine
	-- @v_laize				: Hauteur charge
	-- @v_diametre			: Largeur charge
	-- @v_idmachine			: Emplacement de la charge
	-- @v_sensenroulement	: Sens d'enroulement
	-- @v_CodeABarre		: CAB
	-- @v_StatutBobine		: Etat bobine
	-- @v_DateStockage		: Date de stockage
-- =============================================

CREATE PROCEDURE [dbo].[SPC_CHG_CREERBOBINE]
	@v_idcharge int ,	
	@v_poids smallint = NULL,
	@v_laize smallint = NULL,
	@v_diametre smallint = NULL,
	@v_idmachine int = NULL,
	@v_sensenroulement int = 0,
	@v_CodeABarre varchar(20) = NULL,
	@v_StatutBobine INT = 1,
	@v_DateEncollage DATETIME = NULL
AS

BEGIN

-- Déclaration des variables
-----------------------------
DECLARE
	@v_retour	int,
	@v_local	int

-- Déclaration des constantes
-----------------------------
DECLARE
	@CODE_OK tinyint,
	@CODE_KO tinyint,
	@CODE_KO_FOURNISSEUR_INCONNU TINYINT,
	@v_transaction varchar(20)

-- Définition des constantes
-----------------------------------------
SET @CODE_OK = 0
SET @CODE_KO = 1
SET @CODE_KO_FOURNISSEUR_INCONNU = 2


-- Initialisation des variables
-------------------------------
set @v_transaction = 'SPC_CHG_CREERBOBINE'
SET @v_retour = @CODE_OK
SET @v_idcharge = 0

-- SET NOCOUNT ON added to prevent extra result sets from
-- interfering with SELECT statements.
SET NOCOUNT ON;

-- Gestion des ouvertures de transactions
-----------------------------------------
	IF @@TRANCOUNT > 0
		SET @v_local = 0
	ELSE
	BEGIN
		SET @v_local = 1
		BEGIN TRAN @v_transaction
	END


		
-- Gestion des fermetures de transactions
-----------------------------------------
	IF @v_retour <> @CODE_OK
	BEGIN
		IF @v_local = 1
			ROLLBACK TRAN @v_transaction
	END
	ELSE IF @v_local = 1
		COMMIT TRAN @v_transaction
	RETURN @v_retour

END

