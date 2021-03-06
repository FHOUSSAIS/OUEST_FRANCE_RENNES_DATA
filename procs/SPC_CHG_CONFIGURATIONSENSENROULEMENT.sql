SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
-- =============================================
-- Description:	Configuration du sens d'enroulement
	-- @v_action			: Action (Création/Modification/Suppression)
	-- @v_idFournisseur		: Identifiant Fournisseur
	-- @v_machine			: Numéro de machine
	-- @v_orientation		: Sens d'enroulement
-- =============================================
CREATE PROCEDURE [dbo].[SPC_CHG_CONFIGURATIONSENSENROULEMENT]
	@v_action        int,
	@v_idFournisseur int,
	@v_machine       int,
	@v_orientation   int
AS
BEGIN

declare @CODE_OK int,
		@CODE_KO int

declare @retour int,
		@procStock varchar(128),
		@chaineTrace varchar(7500)

set @CODE_OK = 0
set @CODE_KO = 1

set @retour = @CODE_OK
set @procStock = 'SPC_CHG_CONFIGURATIONSENSENROULEMENT'

-- =============================================
-- ACTION 1 : Nouvelle Association
-- =============================================
	if( @v_action = 1 )
	begin
		if(exists( select 1 from SPC_CHARGE_ENROULEMENT where SER_IDFOURNISSEUR = @v_idFournisseur and SER_IDMACHINE = @v_machine ))
		begin
			return -980 -- Correspondance Fournisseur / Machine / Sens Enroulement existe déjà
		end
		else
		begin
			insert into SPC_CHARGE_ENROULEMENT( SER_IDFOURNISSEUR, SER_IDMACHINE, SER_ORIENTATION )
			values( @v_idFournisseur, @v_machine, @v_orientation )
			
			set @retour = @@ERROR
			if( @retour <> @CODE_OK )
			begin
				set @chaineTrace = 'Insertion Correspondance : ' + CONVERT( varchar, ISNULL( @retour, -1 ) )
				exec INT_ADDTRACESPECIFIQUE @procStock, '[ERRCHG]', @chaineTrace
			end
		end
 	end
-- =============================================
-- ACTION 2 : Suppression Association
-- =============================================
	else if( @v_action = 2 )
	begin
		delete from SPC_CHARGE_ENROULEMENT
		where SER_IDFOURNISSEUR = @v_idFournisseur
		and   SER_IDMACHINE     = @v_machine
		and   SER_ORIENTATION   = @v_orientation
	end
-- =============================================
-- ACTION 3 : Modification Association
-- =============================================
	else 
	begin
		update SPC_CHARGE_ENROULEMENT set SER_ORIENTATION = @v_orientation
		where SER_IDFOURNISSEUR = @v_idFournisseur
		and   SER_IDMACHINE     = @v_machine
	end
END

